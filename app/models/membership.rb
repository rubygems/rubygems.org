# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  belongs_to :invited_by, class_name: "User", optional: true

  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  enum :role, { owner: Access::OWNER, admin: Access::ADMIN, maintainer: Access::MAINTAINER }, validate: true, default: :maintainer

  scope :with_minimum_role, ->(role) { where(role: Access.flag_for_role(role)...) }

  scope :by_organization_handle, -> { joins(:organization).order("organizations.handle ASC") }

  validates :user, uniqueness: { scope: :organization }

  def self.update_notifier(to_enable, to_disable, notifier_attr)
    where(id: to_enable).update_all(notifier_attr => true) if to_enable.any?
    where(id: to_disable).update_all(notifier_attr => false) if to_disable.any?
  end

  def self.update_push_notifier(to_enable_push, to_disable_push)
    update_notifier(to_enable_push, to_disable_push, "push_notifier")
  end

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
