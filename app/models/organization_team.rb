# frozen_string_literal: true

class OrganizationTeam < ApplicationRecord
  belongs_to :organization

  validates :handle, presence: true,
    uniqueness: { case_sensitive: false, scope: :organization },
    length: { within: 2..40 },
    format: { with: Patterns::ORGANIZATION_HANDLE_PATTERN }

  validates :name, presence: true,
    length: { within: 2..255 }

  def self.find_by_handle!(handle)
    find_by!("lower(handle) = lower(?)", handle)
  end

  def to_param
    handle
  end
end
