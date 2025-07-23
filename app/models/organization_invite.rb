class OrganizationInvite < ApplicationRecord
  belongs_to :invitable, polymorphic: true
  belongs_to :user

  validates :user_id, uniqueness: { scope: %i[invitable_type invitable_id] }

  enum :role, { owner: "owner", admin: "admin", maintainer: "maintainer", outside_contributor: "outside_contributor" },
    validate: { allow_nil: true }

  def to_membership(actor: nil)
    return nil if role.blank? || outside_contributor?

    Membership.new(
      user: user,
      role: role,
      invited_by: actor
    )
  end
end
