FactoryBot.define do
  factory :events_organization_event, class: "Events::OrganizationEvent" do
    tag { "organization:created" }
    organization
    ip_address
    additional { nil }
  end
end
