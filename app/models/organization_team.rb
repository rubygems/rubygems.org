# frozen_string_literal: true

class OrganizationTeam < ApplicationRecord
  belongs_to :organization

  validates :handle, presence: true,
    uniqueness: { case_sensitive: false, scope: :organization },
    length: { within: 2..40 },
    format: { with: Patterns::ORGANIZATION_HANDLE_PATTERN }

  validates :name, presence: true,
    length: { within: 2..255 }
end
