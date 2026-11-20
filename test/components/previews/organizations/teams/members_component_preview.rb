# frozen_string_literal: true

class Organizations::Teams::MembersComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param can_manage toggle "can_manage"
  def default(can_manage: true)
    organization = Organization.new(handle: "acme", name: "Acme")
    team = OrganizationTeam.new(handle: "core", name: "Core Team", organization:)

    render Organizations::Teams::MembersComponent.new(
      team:,
      team_memberships: [
        team_membership(membership(1, "alice", "Alice Smith", public_email: true), 3.days.ago),
        team_membership(membership(2, "bob", nil), 1.hour.ago)
      ],
      addable_memberships: [
        membership(3, "dave", "Dave Kim", public_email: true),
        membership(4, "erin", "Erin Park"),
        membership(5, "frank", nil, public_email: true)
      ],
      can_manage:
    )
  end

  private

  def team_membership(membership, added_at)
    OrganizationTeamMembership.new(membership:, created_at: added_at)
  end

  def membership(id, handle, full_name, public_email: false)
    user = User.new(handle:, full_name:, email: "#{handle}@rubygems.test", public_email:)
    Membership.new(id:, user:, confirmed_at: Time.zone.now)
  end
end
