ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'rr'

require 'capybara/rails'
require 'clearance/test_unit'
require 'rubygems/package'
require 'shoulda'

require 'helpers/gem_helpers'

I18n.enforce_available_locales = false

class Test::Unit::TestCase
  include Rack::Test::Methods
  include FactoryGirl::Syntax::Methods
  include GemHelpers

  def setup
    RR.reset
    $redis.flushdb
    $fog.directories.create(:key => $rubygems_config[:s3_bucket], :public => true)
  end

  def page
    Capybara::Node::Simple.new(@response.body)
  end

  def assert_changed(object, attribute, &block)
    original = object.send(attribute)
    yield
    latest = object.reload.send(attribute)
    assert_not_equal original, latest,
      "Expected #{object.class} #{attribute} to change but still #{latest}"
  end
end

# why isn't clearance doing this for us!?
class ActionController::TestCase
  setup do
    @request.env[:clearance] = Clearance::Session.new(@request.env)
  end
end

class SystemTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  def setup
    Capybara.app = Gemcutter::Application
  end

  def teardown
    Capybara.reset_sessions!
  end
end
