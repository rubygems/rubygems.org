FactoryBot.define do
  factory :events_user_event, class: "Events::UserEvent" do
    tag { "user:login:success" }
    user
    ip_address
    additional { nil }
  end
end
