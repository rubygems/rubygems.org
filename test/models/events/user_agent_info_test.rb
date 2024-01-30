require "test_helper"

class Events::UserAgentInfoTest < ActiveSupport::TestCase
  test "#to_s" do
    assert_equal "user_agent (os on device)", build(:events_user_agent_info, installer: "Browser").to_s
    assert_equal "user_agent (os)", build(:events_user_agent_info, installer: "Browser", device: "Other").to_s
    assert_equal "user_agent (device)", build(:events_user_agent_info, installer: "Browser", os: "Other").to_s
    assert_equal "user_agent", build(:events_user_agent_info, installer: "Browser", os: "Other", device: "Other").to_s
    assert_equal "Unknown browser", build(:events_user_agent_info, installer: "Browser", device: "Other", os: "Other", user_agent: "Other").to_s

    assert_equal "installer (implementation on system)", build(:events_user_agent_info).to_s
    assert_equal "installer (implementation)", build(:events_user_agent_info, system: nil).to_s
    assert_equal "installer (system)", build(:events_user_agent_info, implementation: nil).to_s
    assert_equal "installer", build(:events_user_agent_info, system: nil, implementation: nil).to_s

    assert_equal "Unknown user agent", build(:events_user_agent_info, installer: nil).to_s
  end
end
