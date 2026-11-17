# frozen_string_literal: true

require "test_helper"
class OrganizationTeamPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @admin = create(:user, handle: "admin")
    @maintainer = create(:user, handle: "maintainer")
    @guest = create(:user)
    @organization = create(:organization, owners: [@owner], admins: [@admin], maintainers: [@maintainer])
    @team = @organization.organization_teams.build
  end

  def policy!(user)
    Pundit.policy!(user, @team)
  end

  context "#show?" do
    should "be authorized for org members" do
      assert_authorized @owner, :show?
      assert_authorized @admin, :show?
      assert_authorized @maintainer, :show?

      refute_authorized @guest, :show?
    end
  end

  %i[add_member? remove_member?].each do |action|
    context "##{action}" do
      should "be authorized for org owners and admins only" do
        assert_authorized @owner, action
        assert_authorized @admin, action

        refute_authorized @maintainer, action
        refute_authorized @guest, action
      end
    end
  end

  context "with a team that has no organization" do
    setup do
      @team = OrganizationTeam.new
    end

    should "not be authorized for anyone" do
      refute_authorized @owner, :show?
      refute_authorized @owner, :add_member?
      refute_authorized @owner, :remove_member?
    end
  end
end
