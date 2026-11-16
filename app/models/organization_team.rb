# frozen_string_literal: true

class OrganizationTeam < ApplicationRecord
  belongs_to :organization

  validates :handle, presence: true,
    uniqueness: { case_sensitive: false, scope: :organization },
    length: { within: 2..40 },
    format: { with: Patterns::ORGANIZATION_HANDLE_PATTERN }

  validates :name, presence: true,
    length: { within: 2..255 }

  def save_with_creation_event(actor:)
    return false unless new_record?

    transaction do
      save && organization.record_event!(Events::OrganizationEvent::TEAM_CREATED,
        team: handle, team_gid: to_gid,
        created_by: actor.display_handle, actor_gid: actor.to_gid)
    end
  end

  def self.find_by_handle!(handle)
    find_by!("lower(handle) = lower(?)", handle)
  end

  def to_param
    handle
  end
end
