require "test_helper"

# Workaround for ChromeDriver bug where Turbo Drive DOM replacement causes
# "Node with given id does not belong to the document" to be raised as a generic
# UnknownError instead of StaleElementReferenceError. Capybara only retries the
# latter, so the error crashes the test instead of being retried.
# See: https://github.com/SeleniumHQ/selenium/issues/15401
# TODO: Remove when migrating to Playwright (capybara-playwright-driver)
module ChromeNodeStaleElementPatch
  def visible?
    super
  rescue Selenium::WebDriver::Error::UnknownError => e
    raise Selenium::WebDriver::Error::StaleElementReferenceError, e.message if e.message.include?("does not belong to the document")
    raise
  end
end
Capybara::Selenium::ChromeNode.prepend(ChromeNodeStaleElementPatch)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include OauthHelpers
  include AvoHelpers

  if ENV["CAPYBARA_SERVER_PORT"]
    served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"]

    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400], options: {
      browser: :remote,
      url: "http://#{ENV['SELENIUM_HOST']}:4444"
    }
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
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
