FactoryBot.define do
  factory :events_org_event, class: "Events::OrgEvent" do
    tag { "org:created" }
    org
    ip_address
    additional { nil }
  end
end
