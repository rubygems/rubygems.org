ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

require "rails/test_help"
require "mocha/minitest"
require "capybara/rails"
require "capybara/minitest"
require "clearance/test_unit"
require "shoulda"
require "helpers/gem_helpers"
require "helpers/email_helpers"
require "helpers/es_helper"
require "helpers/password_helpers"
require "simplecov"

SimpleCov.start "rails"

RubygemFs.mock!
Aws.config[:stub_responses] = true

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include GemHelpers
  include EmailHelpers
  include PasswordHelpers

  parallelize_setup { |worker| ENV["WORKER_NUMBER"] = worker.to_s }
  
  parallelize(workers: :number_of_processors)

  setup do
    I18n.locale = :en
    Rails.cache.clear

    # Don't connect to the Pwned Passwords API in tests
    Pwned.stubs(:pwned?).returns(false)
  end

  def page
    Capybara::Node::Simple.new(@response.body)
  end

  def requires_toxiproxy
    skip("Toxiproxy is not running, but was required for this test.") unless Toxiproxy.running?
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

  def headless_chrome_driver
    Capybara.current_driver = :selenium_chrome_headless
    Capybara.default_max_wait_time = 2
    Selenium::WebDriver.logger.level = :error
  end
end

class ActionDispatch::IntegrationTest
  setup { host! Gemcutter::HOST }
end
Capybara.app_host = "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"
Capybara.always_include_port = true

class SystemTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
