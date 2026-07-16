# frozen_string_literal: true

class HistoricalOwnership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user

  enum :role, { owner: Access::OWNER, maintainer: Access::MAINTAINER }, validate: true
  ROLE_HIERARCHY = %w[maintainer owner].freeze # Lowest to highest privilege

  scope :current, -> { where(removed_at: nil) }
  scope :alumni, -> { where.not(removed_at: nil) }

  def self.roles_below(role)
    ROLE_HIERARCHY.first(ROLE_HIERARCHY.index(role.to_s))
  end
end
