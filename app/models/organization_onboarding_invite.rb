class OrganizationOnboardingInvite < ApplicationRecord
  belongs_to :organization_onboarding, inverse_of: :invites
  belongs_to :user

  validates :role, presence: true, inclusion: { in: Membership.roles.keys }

  # delegate oid,  attributes to user

  def to_membership
    Membership.new(
      user: user,
      role: role
    )
  end
end
