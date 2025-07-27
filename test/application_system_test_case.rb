require "test_helper"

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

    assert page.has_content?("Dashboard")
  end

  def sign_out
    reset_session!
    visit "/"

    assert page.has_content?("Sign in".upcase)
  end
end
