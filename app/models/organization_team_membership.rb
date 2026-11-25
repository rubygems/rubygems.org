# frozen_string_literal: true

class OrganizationTeamMembership < ApplicationRecord
  belongs_to :organization_team
  belongs_to :membership

  validates :membership_id, uniqueness: { scope: :organization_team_id }
  validate :membership_confirmed
  validate :membership_in_team_organization

  private

  def membership_confirmed
    return if membership.blank? || membership.confirmed?

    errors.add(:membership, "must be confirmed")
  end

  def membership_in_team_organization
    return if organization_team.blank? || membership.blank?
    return if membership.organization_id == organization_team.organization_id

    errors.add(:membership, "must belong to the team's organization")
  end
end
