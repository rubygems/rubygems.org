# frozen_string_literal: true

require "test_helper"

class OrganizationTeamMembershipTest < ActiveSupport::TestCase
  setup do
    @team = create(:organization_team)
    @organization = @team.organization
  end

  should "be valid for a confirmed member of the team's organization" do
    membership = create(:membership, organization: @organization)

    assert_predicate OrganizationTeamMembership.new(organization_team: @team, membership:), :valid?
  end

  should "reject the same membership twice on a team" do
    existing = create(:organization_team_membership, organization_team: @team)
    duplicate = OrganizationTeamMembership.new(organization_team: @team, membership: existing.membership)

    refute_predicate duplicate, :valid?
    assert_includes duplicate.errors[:membership_id], "has already been taken"
  end

  should "reject an unconfirmed membership" do
    membership = create(:membership, :pending, organization: @organization)
    team_membership = OrganizationTeamMembership.new(organization_team: @team, membership:)

    refute_predicate team_membership, :valid?
    assert_includes team_membership.errors[:membership], "must be confirmed"
  end

  should "reject a membership from another organization" do
    membership = create(:membership)
    team_membership = OrganizationTeamMembership.new(organization_team: @team, membership:)

    refute_predicate team_membership, :valid?
    assert_includes team_membership.errors[:membership], "must belong to the team's organization"
  end
end
