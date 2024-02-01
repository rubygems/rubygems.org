FactoryBot.define do
  factory :events_rubygem_event, class: "Events::RubygemEvent" do
    tag { "rubygem:owner:added" }
    rubygem
    ip_address
    additional { nil }
  end
end
