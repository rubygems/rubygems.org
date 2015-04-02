ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)

require 'minitest/autorun'
# Workaround https://github.com/rr/rr/pull/60
Minitest::VERSION = Minitest::Unit::VERSION unless defined?(Minitest::VERSION)
require 'rails/test_help'
require 'rr'
require 'capybara/rails'
require 'clearance/test_unit'
require 'rubygems/package'
require 'shoulda'

require 'helpers/gem_helpers'

I18n.enforce_available_locales = false

# Shim for compatibility with older versions of MiniTest
MiniTest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

require 'fog'
Fog.mock!
$fog = Fog::Storage.new(provider: 'AWS', aws_access_key_id: '', aws_secret_access_key: '')

class MiniTest::Test
  include Rack::Test::Methods
  include FactoryGirl::Syntax::Methods
  include GemHelpers

  def setup
    RR.reset
    Redis.current.flushdb
    $fog.directories.create(key: Gemcutter.config['s3_bucket'], public: true)
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

class ActionDispatch::IntegrationTest
  setup { host! Gemcutter::HOST }
end
Capybara.app_host = "http://#{Gemcutter::HOST}"

class SystemTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
end
