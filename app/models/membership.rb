class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  enum :role, { owner: Access::OWNER, admin: Access::ADMIN, maintainer: Access::MAINTAINER }, validate: true, default: :maintainer

  scope :with_minimum_role, ->(role) { where(role: Access.flag_for_role(role)...) }

  def confirmed?
    !confirmed_at.nil?
  end
end
