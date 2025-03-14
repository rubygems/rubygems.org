require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include OauthHelpers
  include AvoHelpers

  if ENV["CAPYBARA_SERVER_PORT"]
    served_by host: "rails-app", port: ENV["CAPYBARA_SERVER_PORT"]

    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400], options: {
      browser: :remote,
      url: "http://#{ENV['SELENIUM_HOST']}:4444"
    } do |options|
      options.binary = ENV['CHROME_PATH'] if ENV['CHROME_PATH'].present?
    end
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |options|
      options.binary = ENV['CHROME_PATH'] if ENV['CHROME_PATH'].present?
    end
  end
end
