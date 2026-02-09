class Organization < ApplicationRecord
  include Events::Recordable

  validates :handle, presence: true,
    uniqueness: { case_sensitive: false },
    length: { within: 2..40 },
    format: { with: Patterns::HANDLE_PATTERN }
  validates :name, presence: true, length: { within: 2..255 }
  validate :handle_not_reserved

  has_many :memberships, -> { where.not(confirmed_at: nil) }, dependent: :destroy, inverse_of: :organization
  has_many :unconfirmed_memberships, -> { where(confirmed_at: nil) }, class_name: "Membership", dependent: :destroy, inverse_of: :organization
  has_many :memberships_including_unconfirmed, class_name: "Membership", dependent: :destroy, inverse_of: :organization
  has_many :users, through: :memberships
  has_many :rubygems, dependent: :nullify
  has_many :audits, as: :auditable, dependent: :nullify
  has_one :organization_onboarding, foreign_key: :onboarded_organization_id, inverse_of: :organization, dependent: :destroy

  default_scope { not_deleted }
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :deleted, -> { unscoped.where.not(deleted_at: nil) }

  after_create do
    record_event!(Events::OrganizationEvent::CREATED, actor_gid: memberships.first&.to_gid)
  end

  def user_is_member?(user)
    memberships.exists?(user: user)
  end

  def self.find_by_handle(handle)
    return where("lower(handle) IN (?)", handle.map(&:downcase)) if handle.is_a?(Array)

    find_by("lower(handle) = lower(?)", handle)
  end

  def self.find_by_handle!(handle)
    result = find_by_handle(handle)

    raise ActiveRecord::RecordNotFound if handle.is_a?(Array) && result.empty?

    result || raise(ActiveRecord::RecordNotFound)
  end

  def to_param
    handle
  end

  def flipper_id
    "org:#{handle}"
  end

  private

  def handle_not_reserved
    return if handle.blank?

    return unless Handle.reserved?(handle)

    errors.add(:handle, "is reserved and cannot be used")
  end
end
