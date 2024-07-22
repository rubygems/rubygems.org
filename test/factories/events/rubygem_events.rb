FactoryBot.define do
  factory :events_rubygem_event, class: "Events::RubygemEvent" do
    tag { Events::RubygemEvent::OWNER_ADDED }
    rubygem
    ip_address
    additional { nil }
  end
end
