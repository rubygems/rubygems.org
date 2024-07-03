class Org < ApplicationRecord
  validates :handle, presence: true,
    uniqueness: { case_sensitive: false },
    length: { within: 2..40 },
    format: { with: /\A[A-Za-z][A-Za-z_\-0-9]*\z/ }
  validates :name, presence: true, length: { within: 2..255 }
  validate :unique_with_user_handle

  def unique_with_user_handle
    errors.add(:handle, "has already been taken") if handle && User.where("handle = lower(?)", handle.downcase).any?
  end

  has_many :rubygems, through: :ownerships
  has_many :memberships, -> { where.not(confirmed_at: nil) }, dependent: :destroy, inverse_of: :org
  has_many :unconfirmed_memberships, -> { where(confirmed_at: nil) }, class_name: "Membership", dependent: :destroy, inverse_of: :org
  has_many :users, through: :memberships

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
end
