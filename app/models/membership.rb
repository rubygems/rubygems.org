class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  enum :role, { owner: Access::OWNER, maintainer: Access::MAINTAINER, admin: Access::ADMIN }, validate: true, default: :maintainer

  def confirmed?
    !confirmed_at.nil?
  end
end
