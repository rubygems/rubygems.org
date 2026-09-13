# frozen_string_literal: true

class HistoricalOwnership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user

  scope :current, -> { where(removed_at: nil) }
  scope :alumni, -> { where.not(removed_at: nil) }
  scope :not_private, -> { where(private_at: nil) }

  def private?
    private_at.present?
  end

  def make_private!
    update!(private_at: Time.current) unless private?
  end

  def make_public!
    update!(private_at: nil) if private?
  end
end
