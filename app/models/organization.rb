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
end
