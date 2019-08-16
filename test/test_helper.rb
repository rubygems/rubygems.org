ENV["RAILS_ENV"] ||= "test"
ENV["WEBAUTHN_ORIGIN"] ||= "http://test.host"
require File.expand_path("../config/environment", __dir__)

require "rails/test_help"
require "mocha/mini_test"
require "capybara/rails"
require "clearance/test_unit"
require "shoulda"
require "helpers/gem_helpers"
require "helpers/email_helpers"
require "helpers/es_helper"

RubygemFs.mock!
Aws.config[:stub_responses] = true

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include GemHelpers
  include EmailHelpers

  setup do
    I18n.locale = :en
    Rails.cache.clear
  end

  def page
    Capybara::Node::Simple.new(@response.body)
  end

  def requires_toxiproxy
    skip("Toxiproxy is not running, but was required for this test.") unless Toxiproxy.running?
  end

  def assert_changed(object, *attributes)
    original_attributes = attributes.map { |a| [a, object.send(a)] }.to_h
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
Capybara.app_host = "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"

class SystemTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
