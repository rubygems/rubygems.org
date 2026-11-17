# frozen_string_literal: true

class Organizations::Teams::MembersComponentPreview < Lookbook::Preview
  layout "hammy_component_preview"

  # @param can_manage toggle "can_manage"
  def default(can_manage: true)
    organization = Organization.new(handle: "acme", name: "Acme")
    team = OrganizationTeam.new(handle: "core", name: "Core Team", organization:)

    render Organizations::Teams::MembersComponent.new(
      team:,
      members: [membership(1, "alice", "Alice Smith"), membership(2, "bob", nil)],
      addable_memberships: [
        membership(3, "dave", "Dave Kim", public_email: true),
        membership(4, "erin", "Erin Park"),
        membership(5, "frank", nil, public_email: true)
      ],
      can_manage:
    )
  end

  private

  def membership(id, handle, full_name, public_email: false)
    user = User.new(handle:, full_name:, email: "#{handle}@rubygems.test", public_email:)
    Membership.new(id:, user:, confirmed_at: Time.zone.now)
  end
end
