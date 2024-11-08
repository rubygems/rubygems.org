class OrganizationOnboardingInvite < ApplicationRecord
  belongs_to :organization_onboarding, inverse_of: :invites
  belongs_to :user, optional: true

  validates :role, inclusion: { in: Membership.roles.keys, allow_blank: true }
  validates :user_id, presence: true, uniqueness: { scope: :organization_onboarding_id }

  Membership.roles.keys.each do |role|
    define_method("#{role}?") do
      self.role == role
    end
  end
  # delegate oid,  attributes to user

  def to_membership
    return if role.blank?
    Membership.new(
      user: user,
      role: role
    )
  end
end
