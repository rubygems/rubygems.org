class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  belongs_to :invited_by, class_name: "User", optional: true

  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  enum :role, { owner: Access::OWNER, admin: Access::ADMIN, maintainer: Access::MAINTAINER }, validate: true, default: :maintainer

  scope :with_minimum_role, ->(role) { where(role: Access.flag_for_role(role)...) }

  validates :user, uniqueness: { scope: :organization }

  before_create :set_invitation_expire_time

  def confirm!
    update_attribute(:confirmed_at, Time.zone.now)
  end

  def confirmed?
    confirmed_at.present?
  end

  def refresh_invitation!
    set_invitation_expire_time
    save!
  end

  private

  def set_invitation_expire_time
    self.invitation_expires_at = Gemcutter::MEMBERSHIP_INVITE_EXPIRES_AFTER.from_now
  end
end
