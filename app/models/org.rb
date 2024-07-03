class Org < ApplicationRecord
  validates :handle, presence: true, uniqueness: true
  validates :name, presence: true
  validate :unique_with_user_handle

  def unique_with_user_handle
    errors.add(:handle, "is not available") if User.exists?(handle: handle)
  end

  has_many :rubygems, through: :ownerships
  has_many :memberships, -> { where.not(confirmed_at: nil) }, dependent: :destroy, inverse_of: :org
  has_many :unconfirmed_memberships, -> { where(confirmed_at: nil) }, class_name: "Membership", dependent: :destroy, inverse_of: :org
  has_many :users, through: :memberships
end
