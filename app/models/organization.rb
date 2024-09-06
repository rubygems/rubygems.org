class Organization < ApplicationRecord
  include Events::Recordable

  validates :handle, presence: true,
    uniqueness: { case_sensitive: false },
    length: { within: 2..40 },
    format: { with: Patterns::HANDLE_PATTERN }
  validates :name, presence: true, length: { within: 2..255 }
  validate :unique_with_user_handle

  def unique_with_user_handle
    errors.add(:handle, "has already been taken") if handle && User.where("lower(handle) = lower(?)", handle).any?
  end

  has_many :memberships, -> { where.not(confirmed_at: nil) }, dependent: :destroy, inverse_of: :organization
  has_many :unconfirmed_memberships, -> { where(confirmed_at: nil) }, class_name: "Membership", dependent: :destroy, inverse_of: :organization
  has_many :users, through: :memberships

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  after_create do
    record_event!(Events::OrganizationEvent::CREATED, actor_gid: memberships.first&.to_gid)
  end

  def self.find_by_handle(handle)
    not_deleted.find_by("lower(handle) = lower(?)", handle)
  end

  def self.find_by_handle!(handle)
    find_by_handle(handle) || raise(ActiveRecord::RecordNotFound)
  end

  def to_param
    handle
  end

  def confirm_membership!(user)
    membership = unconfirmed_memberships.find_by(user: user)
    membership.update!(confirmed_at: Time.current)
    record_event!(Events::OrganizationEvent::MEMBERSHIP_CONFIRMED, actor_gid: membership.to_gid)
  end

  def add_member!(user, role)
    memberships.create!(user: user, role: role)
  end

  def remove_member!(user)
    membership = memberships.find_by(user: user)
    membership.destroy!
    record_event!(Events::OrganizationEvent::MEMBERSHIP_REMOVED, actor_gid: membership.to_gid)
  end

  def delete!
    update!(deleted_at: Time.current)
    record_event!(Events::OrganizationEvent::DELETED, actor_gid: memberships.first&.to_gid)
  end

  def deleted?
    deleted_at.present?
  end
end
