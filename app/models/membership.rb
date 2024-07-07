class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :org

  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def confirmed?
    !confirmed_at.nil?
  end
end
