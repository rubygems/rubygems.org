require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include OauthHelpers
  include AvoHelpers

  if ENV["CAPYBARA_SERVER_PORT"]
    served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"]

    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400], options: {
      browser: :remote,
      url: "http://#{ENV['SELENIUM_HOST']}:4444"
    } do |driver|
      driver.add_argument("--unsafely-treat-insecure-origin-as-secure=http://rails-app:#{ENV['CAPYBARA_SERVER_PORT']}")
    end
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  def devcontainer?
    ENV["DEVCONTAINER_APP_HOST"].present?
  end
end
