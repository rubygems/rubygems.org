class Org < ApplicationRecord
  has_many :rubygems, through: :ownerships
  has_many :memberships, -> { where.not(confirmed_at: nil) }, dependent: :destroy, inverse_of: :org
  has_many :unconfirmed_memberships, -> { where(confirmed_at: nil) }, class_name: "Membership", dependent: :destroy, inverse_of: :org
  has_many :users, through: :memberships
end
