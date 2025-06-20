class OrganizationOnboardingInvite < ApplicationRecord
  belongs_to :organization_onboarding, inverse_of: :invites
  belongs_to :user

  validates :user_id, uniqueness: { scope: :organization_onboarding_id }

  enum :role, { owner: "owner", admin: "admin", maintainer: "maintainer", outside_contributor: "outside_contributor" },
    validate: { allow_nil: true }

  def to_membership(actor: nil)
    Membership.new(
      user: user,
      role: role,
      invited_by: actor
    )
  end
end
