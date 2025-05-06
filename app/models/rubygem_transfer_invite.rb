class RubygemTransferInvite < ApplicationRecord
  belongs_to :rubygem_transfer
  belongs_to :user

  enum :role, { owner: "owner", admin: "admin", maintainer: "maintainer", outside_contributor: "outside_contributor" },
  validate: { allow_nil: true }

  def approved?
    role.present? && user.present?
  end

  def to_membership
    Membership.new(
      user: user,
      role: role
    )
  end
end
