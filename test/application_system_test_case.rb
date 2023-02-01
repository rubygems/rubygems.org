require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # TODO: remove once https://github.com/rails/rails/pull/47117 is released
  Selenium::WebDriver.logger.ignore(:capabilities)
end
