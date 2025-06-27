FactoryBot.define do
  factory :rubygem_transfer do
    rubygem { association :rubygem }
    created_by { association :user }
    organization { association :organization }
  end
end
