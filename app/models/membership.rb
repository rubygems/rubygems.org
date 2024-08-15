class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  attribute :role, Types::Role.new, default: Access::GUEST

  def confirmed?
    !confirmed_at.nil?
  end
end
