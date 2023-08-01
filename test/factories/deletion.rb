FactoryBot.define do
  factory :deletion do
    user
    rubygem { "rubygem-name" }
    version
    number
    platform { "ruby" }
  end
end
