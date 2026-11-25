# frozen_string_literal: true

class OrganizationTeam < ApplicationRecord
  belongs_to :organization
  has_many :team_memberships, -> { order(:created_at, :id) },
    class_name: "OrganizationTeamMembership", dependent: :destroy, inverse_of: :organization_team
  has_many :memberships, through: :team_memberships

  validates :handle, presence: true,
    uniqueness: { case_sensitive: false, scope: :organization },
    length: { within: 2..40 },
    format: { with: Patterns::ORGANIZATION_HANDLE_PATTERN }

  validate :handle_not_reserved

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

  def add_members!(memberships, actor:)
    transaction do
      memberships.map do |membership|
        team_memberships.create!(membership:).tap do
          record_member_event!(Events::OrganizationEvent::TEAM_MEMBER_ADDED, membership, actor)
        end
      end
    end
  end

  def remove_member!(membership, actor:)
    transaction do
      team_memberships.find_by!(membership:).destroy!.tap do
        record_member_event!(Events::OrganizationEvent::TEAM_MEMBER_REMOVED, membership, actor)
      end
    end
  end

  def addable_memberships
    organization.memberships
      .where.not(id: team_memberships.select(:membership_id))
      .joins(:user).includes(:user).order("users.handle")
  end

  def to_param
    handle
  end

  private

  def record_member_event!(tag, membership, actor)
    organization.record_event!(tag,
      team: handle, team_gid: to_gid,
      member: membership.user.display_handle, member_gid: membership.user.to_gid,
      actor: actor.display_handle, actor_gid: actor.to_gid)
  end

  # Team handles are path segments under /organizations/:org/teams, so they
  # can't collide with the routes there (e.g. "new").
  def handle_not_reserved
    return unless Organization::Handle::RESTFUL_ACTIONS.include?(handle.to_s.downcase)

    errors.add(:handle, :reserved)
  end
end
