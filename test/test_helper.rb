require "simplecov"
SimpleCov.start "rails" do
  add_filter "lib/tasks"
  add_filter "lib/lograge"

  if ENV["CI"]
    require "simplecov-cobertura"
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

require "rails/test_help"
require "mocha/minitest"
require "capybara/rails"
require "capybara/minitest"
require "clearance/test_unit"
require "webauthn/fake_client"
require "shoulda"
require "helpers/gem_helpers"
require "helpers/email_helpers"
require "helpers/es_helper"
require "helpers/password_helpers"
require "helpers/webauthn_helpers"

Capybara.default_max_wait_time = 2
Capybara.app_host = "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"
Capybara.always_include_port = true
Capybara.server = :webrick

RubygemFs.mock!
Aws.config[:stub_responses] = true
Mocha.configure do |c|
  c.strict_keyword_argument_matching = true
end

Rubygem.searchkick_reindex(import: false)

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include GemHelpers
  include EmailHelpers
  include PasswordHelpers

  setup do
    I18n.locale = :en
    Rails.cache.clear
    Rack::Attack.cache.store.clear

    Unpwn.offline = true
  end

  def page
    Capybara::Node::Simple.new(@response.body)
  end

  def requires_toxiproxy
    return if Toxiproxy.running?
    raise "Toxiproxy not running, but REQUIRE_TOXIPROXY was set." if ENV["REQUIRE_TOXIPROXY"]
    skip("Toxiproxy is not running, but was required for this test.")
  end

  def assert_changed(object, *attributes)
    original_attributes = attributes.index_with { |a| object.send(a) }
    yield if block_given?
    reloaded_object = object.reload
    attributes.each do |attribute|
      original = original_attributes[attribute]
      latest = reloaded_object.send(attribute)
      assert_not_equal original, latest,
        "Expected #{object.class} #{attribute} to change but still #{latest}"
    end
  end
end

class ActionDispatch::IntegrationTest
  setup { host! Gemcutter::HOST }
end

Gemcutter::Application.load_tasks

class SystemTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  setup do
    Capybara.current_driver = :rack_test
  end

  teardown { reset_session! }
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
