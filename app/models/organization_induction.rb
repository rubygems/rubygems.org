class OrganizationInduction < ApplicationRecord
  belongs_to :principal, polymorphic: true
  belongs_to :user

  validates :user_id, uniqueness: { scope:  [:principal_type, :principal_id] }

  enum :role, { owner: "owner", admin: "admin", maintainer: "maintainer", outside_contributor: "outside_contributor" },
    validate: { allow_nil: true }

  def to_membership
    Membership.new(
      user: user,
      role: role
    )
  end
end
