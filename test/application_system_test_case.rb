require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include OauthHelpers
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # TODO: remove once https://github.com/rails/rails/pull/47117 is released
  Selenium::WebDriver.logger.ignore(:capabilities)

  Capybara.register_driver :fake_safari do |app|
    Capybara::RackTest::Driver.new(app,
      headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_3) AppleWebKit/605.1.15 (KHTML, like Gecko)
         Version/16.4 Safari/605.1.15" })
  end
end
