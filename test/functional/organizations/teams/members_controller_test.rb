# frozen_string_literal: true

require "test_helper"

class Organizations::Teams::MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)
    @user = create(:user)
    @membership = create(:membership, organization: @organization, user: @user, role: :admin)
    @team = create(:organization_team, organization: @organization, handle: "core")
    enable_feature(FeatureFlag::ORGANIZATION_TEAMS, actor: @organization)

    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  teardown do
    disable_feature(FeatureFlag::ORGANIZATION_TEAMS)
  end

  def sign_in_as(user)
    delete sign_out_path
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  def assert_no_team_changes(&)
    assert_no_difference [-> { OrganizationTeamMembership.count }, -> { Events::OrganizationEvent.count }], &
  end

  def add_members(*memberships)
    post organization_team_members_path(@organization, @team), params: { membership_ids: memberships.map(&:id) }
  end

  def remove_member(membership = @member)
    delete organization_team_member_path(@organization, @team, membership)
  end

  context "POST /organizations/:organization_id/teams/:team_id/members" do
    setup do
      @dave = create(:membership, organization: @organization)
      @erin = create(:membership, organization: @organization)
    end

    should "add the selected members for an admin" do
      assert_difference -> { @team.team_memberships.count }, 2 do
        add_members(@dave, @erin)
      end

      assert_redirected_to organization_team_path(@organization, @team)
      assert_equal "Added 2 members to the team.", flash[:notice]
      assert_equal [@dave, @erin].sort_by(&:id), @team.memberships.sort_by(&:id)
    end

    should "add the selected members for an owner" do
      @membership.update!(role: :owner)

      assert_difference -> { @team.team_memberships.count }, 1 do
        add_members(@dave)
      end

      assert_redirected_to organization_team_path(@organization, @team)
    end

    should "record an added event per member" do
      assert_difference -> { @organization.events.where(tag: Events::OrganizationEvent::TEAM_MEMBER_ADDED).count }, 2 do
        add_members(@dave, @erin)
      end
    end

    should "ignore ineligible ids" do
      other_org = create(:membership)
      pending = create(:membership, :pending, organization: @organization)
      already = create(:organization_team_membership, organization_team: @team).membership

      assert_difference [-> { OrganizationTeamMembership.count }, -> { Events::OrganizationEvent.count }], 1 do
        add_members(other_org, pending, already, @dave)
      end

      assert_equal [already, @dave].sort_by(&:id), @team.memberships.sort_by(&:id)
    end

    should "alert when nothing selected" do
      assert_no_team_changes do
        post organization_team_members_path(@organization, @team)
      end

      assert_redirected_to organization_team_path(@organization, @team)
      assert_equal "Select at least one member to add.", flash[:alert]
    end

    should "be not found for a maintainer" do
      @membership.update!(role: :maintainer)

      assert_no_team_changes { add_members(@dave) }

      assert_response :not_found
    end

    should "be not found for a non-member" do
      sign_in_as(create(:user))

      assert_no_team_changes { add_members(@dave) }

      assert_response :not_found
    end

    should "be not found for an admin of a different organization" do
      outsider = create(:user)
      create(:membership, user: outsider, role: :admin)
      sign_in_as(outsider)

      assert_no_team_changes { add_members(@dave) }

      assert_response :not_found
    end

    should "be not found when the feature is disabled for the organization" do
      disable_feature(FeatureFlag::ORGANIZATION_TEAMS)

      assert_no_team_changes { add_members(@dave) }

      assert_response :not_found
    end

    should "redirect to sign in when signed out" do
      delete sign_out_path

      assert_no_team_changes { add_members(@dave) }

      assert_redirected_to sign_in_path
    end
  end

  context "DELETE /organizations/:organization_id/teams/:team_id/members/:id" do
    setup do
      @member = create(:organization_team_membership, organization_team: @team).membership
    end

    should "remove the member for an admin" do
      assert_difference -> { @team.team_memberships.count }, -1 do
        assert_difference -> { @organization.events.where(tag: Events::OrganizationEvent::TEAM_MEMBER_REMOVED).count }, 1 do
          remove_member
        end
      end

      assert_redirected_to organization_team_path(@organization, @team)
      assert_equal "Removed #{@member.user.handle} from the team.", flash[:notice]
    end

    should "be not found for a membership not on the team" do
      other_team = create(:organization_team, organization: @organization)
      elsewhere = create(:organization_team_membership, organization_team: other_team).membership

      assert_no_team_changes { remove_member(elsewhere) }

      assert_response :not_found
    end

    should "not remove from another organization's team with the same handle" do
      foreign_team = create(:organization_team, handle: "core")
      foreign_member = create(:organization_team_membership, organization_team: foreign_team).membership

      assert_no_team_changes { remove_member(foreign_member) }

      assert_response :not_found
    end

    should "be not found for a maintainer" do
      @membership.update!(role: :maintainer)

      assert_no_team_changes { remove_member }

      assert_response :not_found
    end

    should "be not found for a non-member" do
      sign_in_as(create(:user))

      assert_no_team_changes { remove_member }

      assert_response :not_found
    end

    should "be not found when the feature is disabled for the organization" do
      disable_feature(FeatureFlag::ORGANIZATION_TEAMS)

      assert_no_team_changes { remove_member }

      assert_response :not_found
    end

    should "redirect to sign in when signed out" do
      delete sign_out_path

      assert_no_team_changes { remove_member }

      assert_redirected_to sign_in_path
    end
  end
end
