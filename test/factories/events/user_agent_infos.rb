FactoryBot.define do
  factory :events_user_agent_info, class: "Events::UserAgentInfo" do
    skip_create

    installer { "installer" }
    device { "device" }
    os { "os" }
    user_agent { "user_agent" }
    implementation { "implementation" }
    system { "system" }
  end
end
