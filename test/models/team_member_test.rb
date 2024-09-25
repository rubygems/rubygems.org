require "test_helper"

class TeamMemberTest < ActiveSupport::TestCase
  setup do
    @team = create(:team)
    @user = create(:user)

    @team_member = create(:team_member, team: @team, user: @user)
  end

  context "validations" do
    should "validate the presence of a user and team" do
      team_member = TeamMember.new(team: nil, user: nil)

      assert_not team_member.valid?
      assert_includes team_member.errors.messages[:team], "must exist"
      assert_includes team_member.errors.messages[:user], "must exist"
    end

    should "only allow to belong to a given team once" do
      team_member = TeamMember.new(team: @team, user: @user)

      assert_not team_member.valid?
      assert_includes team_member.errors.messages[:user_id], "has already been taken"
    end
  end
end
