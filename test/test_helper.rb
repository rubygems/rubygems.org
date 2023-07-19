require "simplecov"
SimpleCov.start "rails" do
  add_filter "lib/tasks"
  add_filter "lib/rails_development_log_formatter.rb"

  # Will be deleted after all the delayed jobs have run
  add_filter "app/jobs/*_mailer.rb"
  add_filter "app/jobs/delete_user.rb"

  # to be deleted after initial deploy of mailer migration to AM/AJ
  add_filter "app/jobs/email_confirmation_mailer.rb"
  add_filter "app/jobs/email_reset_mailer.rb"
  add_filter "app/jobs/ownership_confirmation_mailer.rb"

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
require "helpers/admin_helpers"
require "helpers/gem_helpers"
require "helpers/email_helpers"
require "helpers/es_helper"
require "helpers/password_helpers"
require "helpers/webauthn_helpers"
require "helpers/oauth_helpers"
require "webmock/minitest"

WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    "chromedriver.storage.googleapis.com",
    "avohq.io"
  ]
)

Capybara.default_max_wait_time = 2
Capybara.app_host = "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}"
Capybara.always_include_port = true
Capybara.server_port = 31_337
Capybara.server = :puma

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
    visit edit_settings_path

    options = ::Selenium::WebDriver::VirtualAuthenticatorOptions.new
    @authenticator = page.driver.browser.add_virtual_authenticator(options)
    WebAuthn::PublicKeyCredentialWithAttestation.any_instance.stubs(:verify).returns true

    credential_nickname = "new cred"
    fill_in "Nickname", with: credential_nickname
    click_on "Register device"

    click_on "[ copy ]"
    @mfa_recovery_codes = find_all(:css, ".recovery-code-list__item").map(&:text)
    check "ack"
    click_on "Continue"

    find("div", text: credential_nickname, match: :first)

    find(:css, ".header__popup-link").click
    click_on "Sign out"

    @user.reload
    @authenticator
  end
end

class ActionDispatch::IntegrationTest
  include OauthHelpers
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
