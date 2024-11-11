FactoryBot.define do
  factory :organization_onboarding_invite do
    organization_onboarding { association(:organization_onboarding) }
    user { association(:user) }
    role { "owner" }
  end
end
