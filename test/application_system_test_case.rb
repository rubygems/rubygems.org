# frozen_string_literal: true

require "test_helper"
require "capybara-playwright-driver"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include OauthHelpers
  include AvoHelpers

  parallelize_setup do |worker|
    SimpleCov.command_name "system-worker-#{worker}"
  end

  served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"] if ENV["CAPYBARA_SERVER_PORT"]

  # Rails' driven_by registers the :playwright Capybara driver itself, so any
  # standalone Capybara.register_driver block would be overwritten. Pass the
  # Capybara::Playwright::Driver options through `options:` instead — that's
  # what gets forwarded to the driver constructor.
  driven_by :playwright, screen_size: [1400, 1400], options: {
    playwright_cli_executable_path: File.expand_path("../bin/playwright", __dir__),
    browser_type: :chromium,
    headless: true
  }

  teardown do
    if page.driver.respond_to?(:with_playwright_page)
      page.driver.with_playwright_page do |pw_page|
        pw_page.context.clear_cookies
        # Clear HTTP cache between tests to prevent stale responses.
        # Pages with Cache-Control: public headers are cached by the browser,
        # causing subsequent tests to see stale content when visiting the same URL.
        cdp = pw_page.context.new_cdp_session(pw_page)
        cdp.send_message("Network.clearBrowserCache")
        cdp.detach
      rescue Playwright::TargetClosedError
        # Browser already closed
      end
    end
  end

  def sign_in(user = nil)
    user ||= @user

    visit sign_in_path
    fill_in "Email or Username", with: user.reload.email
    fill_in "Password", with: user.password
    click_button "Sign in"

    assert_text("Dashboard")
  end

  def sign_out
    reset_session!
    visit "/"

    assert_text("Sign in".upcase)
  end
end
