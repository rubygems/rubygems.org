FactoryGirl.define do
  sequence :number do |n|
    "0.0.#{n}"
  end

  factory :version do
    authors ["Joe User"]
    built_at 1.day.ago
    description "Some awesome gem"
    indexed true
    number
    platform "ruby"
    rubygem
  end
end
