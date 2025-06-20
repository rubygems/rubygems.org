FactoryBot.define do
  factory :organization_induction do
    principal { association(:organization_onboarding) }
    user { association(:user) }
    role { "owner" }
  end
end
