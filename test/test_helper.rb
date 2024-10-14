require "simplecov"
SimpleCov.start "rails" do
  add_filter "lib/tasks"
  add_filter "lib/rails_development_log_formatter.rb"

  if ENV["CI"]
    require "simplecov-cobertura"
    formatter SimpleCov::Formatter::CoberturaFormatter

    # Avo tests are super fragile :'(
    require "minitest/retry"
    Minitest::Retry.use!
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
require "shoulda/context"
require "shoulda/matchers"
require "helpers/admin_helpers"
require "helpers/api_policy_helpers"
require "helpers/gem_helpers"
require "helpers/email_helpers"
require "helpers/es_helper"
require "helpers/password_helpers"
require "helpers/policy_helpers"
require "helpers/webauthn_helpers"
require "helpers/oauth_helpers"
require "helpers/avo_helpers"
require "webmock/minitest"
require "phlex/testing/rails/view_helper"

# setup license early since some tests are testing Avo outside of requests
# and license is set with first request
Avo::Current.license = Avo::Licensing::LicenseManager.new(Avo::Licensing::HQ.new.response).license

WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    "chromedriver.storage.googleapis.com",
    "search" # Devcontainer OpenSearch container
  ]
)
WebMock.globally_stub_request(:after_local_stubs) do |request|
  if WebMock::RequestPattern.new(:get, Addressable::Template.new("https://secure.gravatar.com/avatar/{hash}.png?d=404&r=PG&s={size}")).matches?(request)
    { status: 404, body: "", headers: {} }
  end
end

Capybara.default_max_wait_time = 2
Capybara.app_host = "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"
Capybara.always_include_port = true
Capybara.server_port = 31_337
Capybara.server = :puma, { Silent: true }

GoodJob::Execution.delete_all

RubygemFs.mock!
Aws.config[:stub_responses] = true
Mocha.configure do |c|
  c.strict_keyword_argument_matching = true
end

Rubygem.searchkick_reindex(import: false)

OmniAuth.config.test_mode = true

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include GemHelpers
  include EmailHelpers
  include PasswordHelpers

  parallelize_setup do |_worker|
    SemanticLogger.reopen
  end

  setup do
    I18n.locale = :en
    Rails.cache.clear
    Rack::Attack.cache.store.clear

    Unpwn.offline = true
    OmniAuth.config.mock_auth.clear

    @launch_darkly = LaunchDarkly::Integrations::TestData.data_source
    config = LaunchDarkly::Config.new(data_source: @launch_darkly, send_events: false)
    Rails.configuration.launch_darkly_client = LaunchDarkly::LDClient.new("", config)

    ActionMailer::Base.deliveries.clear
  end

  teardown do
    Rails.configuration.launch_darkly_client.close
  end

  def page
    Capybara::Node::Simple.new(@response.body)
  end

  def requires_toxiproxy
    return if Toxiproxy.running?
    raise "Toxiproxy not running, but REQUIRE_TOXIPROXY was set." if ENV["REQUIRE_TOXIPROXY"]
    skip("Toxiproxy is not running, but was required for this test.")
  end

  def requires_avo_pro
    return if Avo.configuration.license == "advanced" && defined?(Avo::Pro)

    if ActiveRecord::Type::Boolean.new.cast(ENV["REQUIRE_AVO_PRO"])
      raise "REQUIRE_AVO_PRO is set but Avo::Pro is missing in #{Rails.env}." \
            "\nRAILS_GROUPS=#{ENV['RAILS_GROUPS'].inspect}\nAvo.license=#{Avo.license.inspect}"
    end
    skip "avo pro is not present but was required for this test"
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

  def assert_event(tag, expected_additional, actual)
    refute_nil actual, "Expected event with tag #{tag} but none found"
    assert_equal tag, actual.tag
    user_agent_info = actual.additional.user_agent_info

    assert_equal actual.additional_type.new(user_agent_info:, **expected_additional), actual.additional
  end

  def headless_chrome_driver
    Capybara.current_driver = :selenium_chrome_headless
    Capybara.default_max_wait_time = 2
    Selenium::WebDriver.logger.level = :error
  end

  def fullscreen_headless_chrome_driver
    headless_chrome_driver
    driver = page.driver
    fullscreen_width = 1200
    fullscreen_height = 1000
    driver.resize_window_to(driver.current_window_handle, fullscreen_width, fullscreen_height)
  end

  def create_webauthn_credential
    fullscreen_headless_chrome_driver

    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    @authenticator = create_webauthn_credential_while_signed_in

    find(:css, ".header__popup-link").click
    click_on "Sign out"

    @authenticator
  end

  def create_webauthn_credential_while_signed_in
    visit edit_settings_path

    options = ::Selenium::WebDriver::VirtualAuthenticatorOptions.new(
      resident_key: true,
      user_verification: true,
      user_verified: true
    )
    @authenticator = page.driver.browser.add_virtual_authenticator(options)

    credential_nickname = "new cred"
    fill_in "Nickname", with: credential_nickname
    click_on "Register device"

    click_on "Copy to clipboard"
    @mfa_recovery_codes = find(:css, ".recovery-code-list").value.split

    check "ack"
    click_on "Continue"

    visit edit_settings_path
    find("div", text: credential_nickname, match: :first)

    @user.reload
    @authenticator
  end

  def setup_rstuf
    @original_rstuf_enabled = Rstuf.enabled
    @original_base_url = Rstuf.base_url
    Rstuf.base_url = "https://rstuf.example.com"
    Rstuf.enabled = true
  end

  def teardown_rstuf
    Rstuf.enabled = @original_rstuf_enabled
    Rstuf.base_url = @original_base_url
  end
end

class ActionController::TestCase
  def process(...)
    Prosopite.scan do
      super
    end
  end

  def verified_sign_in_as(user)
    sign_in_as(user)
    session[:verification] = 10.minutes.from_now
    session[:verified_user] = user.id
  end

  def assert_text(text, context = page)
    assert context.has_content?(text), "page is missing content #{text}"
  end

  def refute_text(text)
    refute page.has_content?(text), "page has unexpected content #{text}"
  end

  def assert_selector(selector)
    assert page.has_selector?(selector), "page is missing selector #{selector}"
  end

  def refute_selector(selector)
    refute page.has_selector?(selector), "page has unexpected selector #{selector}"
  end
end

class ActionDispatch::IntegrationTest
  include OauthHelpers
  setup { host! Gemcutter::HOST }
end

Gemcutter::Application.load_tasks

# Force loading of ActionDispatch::SystemTesting::* helpers
_ = ActionDispatch::SystemTestCase

class SystemTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelper
  include ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown

  setup do
    Capybara.current_driver = :rack_test
  end
end

class AdminPolicyTestCase < ActiveSupport::TestCase
  def setup
    requires_avo_pro

    @authorization_client = Admin::AuthorizationClient.new
  end

  def assert_authorizes(user, record, action)
    assert @authorization_client.authorize(user, record, action, policy_class: policy_class)
  rescue Avo::NotAuthorizedError
    policy_class ||= policy!(user, record).class

    flunk("Expected #{policy_class} to authorize #{action} on #{record} for #{user}")
  end

  def refute_authorizes(user, record, action)
    assert_raise(Avo::NotAuthorizedError) do
      @authorization_client.authorize(user, record, action, policy_class: policy_class)
    end
  end

  def policy_class
    nil
  end

  def policy!(user, record)
    @authorization_client.policy!(user, record)
  end

  def policy_scope!(user, record)
    @authorization_client.apply_policy(user, record, policy_class: policy_class)
  end
end

class ApiPolicyTestCase < ActiveSupport::TestCase
  include ApiPolicyHelpers
end

class PolicyTestCase < ActiveSupport::TestCase
  include PolicyHelpers
end

class ComponentTest < ActiveSupport::TestCase
  include Phlex::Testing::Rails::ViewHelper
  include Capybara::Minitest::Assertions

  attr_reader :page

  def render(...)
    response = super
    app = ->(_env) { [200, { "Content-Type" => "text/html" }, [response]] }
    session = Capybara::Session.new(:rack_test, app)
    session.visit("/")
    @page = session.document
  end

  def preview(path = preview_path, scenario: :default, **params)
    preview = Lookbook::Engine.previews.find_by_path(path)

    refute_nil preview, "Preview not found: #{path}"
    render_args = preview.render_args(scenario, params:)
    component = render_args.fetch(:component)
    yield component if block_given?
    render component
  end

  def preview_path
    self.class.name.sub(/ComponentTest$/, "").underscore
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
