require "test_helper"

class OrganizationInviteTest < ActiveSupport::TestCase
  test "to_membership returns a Membership for the user with the give role" do
    invite = create(:organization_invite, role: :owner)

    assert_instance_of Membership, invite.to_membership
    assert_equal invite.user, invite.to_membership.user
    assert_equal invite.role, invite.to_membership.role
  end

  test "to_membership returns nil when invite is for outside contributor role" do
    invite = create(:organization_invite, role: :outside_contributor)

    assert_nil invite.to_membership
  end

  test "to_membership sets invited_by to the actor" do
    user = create(:user)
    invite = create(:organization_invite, role: :owner)

    membership = invite.to_membership(actor: user)

    assert_equal user, membership.invited_by
  end
end
