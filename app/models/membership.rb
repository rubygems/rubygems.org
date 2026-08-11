# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  has_many :api_key_organization_scopes, dependent: :destroy

  belongs_to :invited_by, class_name: "User", optional: true

  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  enum :role, { owner: Access::OWNER, admin: Access::ADMIN, maintainer: Access::MAINTAINER }, validate: true, default: :maintainer

  scope :with_minimum_role, ->(role) { where(role: Access.flag_for_role(role)...) }

  validates :user, uniqueness: { scope: :organization }

  before_create :set_invitation_expire_time
  after_update :revoke_org_scoped_api_keys!, if: :saved_change_to_role?

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

  def revoke_org_scoped_api_keys!
    return if admin? || owner?

    api_key_organization_scopes.includes(:api_key).find_each do |scope|
      scope.api_key.soft_delete!(membership: self)
      scope.destroy!
    end
  end

  def set_invitation_expire_time
    self.invitation_expires_at = Gemcutter::MEMBERSHIP_INVITE_EXPIRES_AFTER.from_now
  end
end
