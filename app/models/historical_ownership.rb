# frozen_string_literal: true

class HistoricalOwnership < ApplicationRecord
  belongs_to :rubygem
  belongs_to :user

  # The numeric enum values here are intentionally defined by lib/access.rb in ascending order of privilege.
  enum :role, { owner: Access::OWNER, maintainer: Access::MAINTAINER }, validate: true

  scope :current, -> { where(removed_at: nil) }
  scope :alumni, -> { where.not(removed_at: nil) }
end
