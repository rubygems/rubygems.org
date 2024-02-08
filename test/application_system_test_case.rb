require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include OauthHelpers
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  def user_agent_info
    Events::UserAgentInfo.new(
      installer: "Browser",
      user_agent: "HeadlessChrome",
      os: "Mac OS X",
      device: "Mac"
    )
  end
end
