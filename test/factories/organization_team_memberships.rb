# frozen_string_literal: true

FactoryBot.define do
  factory :organization_team_membership do
    organization_team
    membership { association(:membership, organization: organization_team.organization) }
  end
end
