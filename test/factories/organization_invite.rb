FactoryBot.define do
  factory :organization_invite do
    invitable { association(:organization_onboarding) }
    user { association(:user) }
    role { "owner" }
  end
end
