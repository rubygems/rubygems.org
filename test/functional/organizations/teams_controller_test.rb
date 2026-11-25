# frozen_string_literal: true

require "test_helper"

class Organizations::TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)
    @user = create(:user)
    @membership = create(:membership, organization: @organization, user: @user, role: :admin)
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

  def team_params(handle: "core", name: "Core Team", **extra)
    { organization_team: { handle:, name:, **extra } }
  end

  context "GET /organizations/:organization_handle/teams" do
    should "list this organization's teams ordered by name" do
      create(:organization_team, organization: @organization, name: "Zeta Team")
      create(:organization_team, organization: @organization, name: "Alpha Team")
      create(:organization_team, name: "Someone Else's Team")

      get organization_teams_path(@organization)

      assert_response :success
      assert_equal ["Alpha Team", "Zeta Team"], css_select("[data-testid=team-name]").map(&:text)
      assert_equal 1, css_select("[data-testid=create-team]").size
    end

    should "load the teams with a single query" do
      create_list(:organization_team, 2, organization: @organization)

      assert_queries_match(/FROM "organization_teams"/, count: 1) do
        get organization_teams_path(@organization)
      end

      assert_response :success
      assert_equal 2, css_select("[data-testid=team]").size
    end

    should "show an empty state" do
      get organization_teams_path(@organization)

      assert_response :success
      assert page.has_content? "No teams yet"
    end

    should "list teams for a maintainer without the create button" do
      @membership.update!(role: :maintainer)
      create(:organization_team, organization: @organization, name: "Core Team")

      get organization_teams_path(@organization)

      assert_response :success
      assert_equal ["Core Team"], css_select("[data-testid=team-name]").map(&:text)
      assert_empty css_select("[data-testid=create-team]")
    end

    should "be not found for a non-member" do
      sign_in_as(create(:user))

      get organization_teams_path(@organization)

      assert_response :not_found
    end

    should "redirect to sign in when signed out" do
      delete sign_out_path

      get organization_teams_path(@organization)

      assert_redirected_to sign_in_path
    end

    should "be not found when the feature is disabled for the organization" do
      disable_feature(FeatureFlag::ORGANIZATION_TEAMS)

      get organization_teams_path(@organization)

      assert_response :not_found
    end
  end

  context "GET /organizations/:organization_handle/teams/new" do
    should "render the form for an admin" do
      get new_organization_team_path(@organization)

      assert_response :success
      assert_equal 1, css_select("[data-testid=team-name-field]").size
      assert_equal 1, css_select("[data-testid=team-handle-field]").size
    end

    should "show the create step in the breadcrumbs without the teams list" do
      get new_organization_team_path(@organization)

      assert_select "nav[aria-label=Breadcrumb]" do
        assert_select "a[href=?]", organization_path(@organization)
        assert_select "a[href=?]", organization_teams_path(@organization), count: 0
        assert_select "[aria-current=page]", text: "Create a Team"
      end
    end

    should "render the form for an owner" do
      @membership.update!(role: :owner)

      get new_organization_team_path(@organization)

      assert_response :success
    end

    should "be not found for a maintainer" do
      @membership.update!(role: :maintainer)

      get new_organization_team_path(@organization)

      assert_response :not_found
    end

    should "be not found when the feature is disabled for the organization" do
      disable_feature(FeatureFlag::ORGANIZATION_TEAMS)

      get new_organization_team_path(@organization)

      assert_response :not_found
    end
  end

  context "POST /organizations/:organization_handle/teams" do
    should "create a team for an admin" do
      assert_difference -> { @organization.organization_teams.count }, 1 do
        post organization_teams_path(@organization), params: team_params
      end

      assert_redirected_to organization_teams_path(@organization)
      assert_equal "Team created.", flash[:notice]
      team = @organization.organization_teams.sole

      assert_equal "core", team.handle
      assert_equal "Core Team", team.name
    end

    should "record a team created event on the organization" do
      assert_difference -> { @organization.events.where(tag: Events::OrganizationEvent::TEAM_CREATED).count }, 1 do
        post organization_teams_path(@organization), params: team_params
      end

      team = @organization.organization_teams.sole
      event = @organization.events.where(tag: Events::OrganizationEvent::TEAM_CREATED).sole

      assert_equal "core", event.additional.team
      assert_equal team, event.additional.team_gid.find
      assert_equal @user.display_handle, event.additional.created_by
      assert_equal @user, event.additional.actor_gid.find
      assert_equal "127.0.0.1", event.ip_address.ip_address.to_s
    end

    should "create a team for an owner" do
      @membership.update!(role: :owner)

      assert_difference -> { @organization.organization_teams.count }, 1 do
        post organization_teams_path(@organization), params: team_params
      end

      assert_redirected_to organization_teams_path(@organization)
    end

    should "re-render the form with errors when invalid" do
      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        post organization_teams_path(@organization), params: team_params(handle: "has space")
      end

      assert_response :unprocessable_content
      assert page.has_content? "Handle is invalid"
    end

    should "reject a handle that is a reserved route word" do
      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        post organization_teams_path(@organization), params: team_params(handle: "new")
      end

      assert_response :unprocessable_content
      assert page.has_content? "Handle is reserved and cannot be used"
    end

    should "reject a handle already used in the organization" do
      create(:organization_team, organization: @organization, handle: "core")

      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        post organization_teams_path(@organization), params: team_params(handle: "CORE")
      end

      assert_response :unprocessable_content
      assert page.has_content? "Handle has already been taken"
    end

    should "not create a team for a maintainer" do
      @membership.update!(role: :maintainer)

      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        post organization_teams_path(@organization), params: team_params
      end

      assert_response :not_found
    end

    should "not create a team for a non-member" do
      sign_in_as(create(:user))

      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        post organization_teams_path(@organization), params: team_params
      end

      assert_response :not_found
    end

    should "not create a team for an admin of a different organization" do
      other_organization = create(:organization)
      enable_feature(FeatureFlag::ORGANIZATION_TEAMS, actor: other_organization)

      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        post organization_teams_path(other_organization), params: team_params
      end

      assert_response :not_found
    end

    should "not create a team when signed out" do
      delete sign_out_path

      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        post organization_teams_path(@organization), params: team_params
      end

      assert_redirected_to sign_in_path
    end

    should "not create a team when the feature is disabled for the organization" do
      disable_feature(FeatureFlag::ORGANIZATION_TEAMS)

      assert_no_difference [-> { OrganizationTeam.count }, -> { Events::OrganizationEvent.count }] do
        post organization_teams_path(@organization), params: team_params
      end

      assert_response :not_found
    end
  end

  context "GET /organizations/:organization_handle/teams/:handle" do
    setup do
      @team = create(:organization_team, organization: @organization, handle: "core", name: "Core Team")
    end

    should "show the team to an admin" do
      get organization_team_path(@organization, @team)

      assert_response :success
      assert_select "[data-testid=team-show-name]", text: "Core Team"
      assert_select "[data-testid=team-show-handle]", text: "core"
    end

    should "show the team to a maintainer" do
      @membership.update!(role: :maintainer)

      get organization_team_path(@organization, @team)

      assert_response :success
    end

    should "find the team by handle case-insensitively" do
      get organization_team_path(@organization, "CORE")

      assert_response :success
      assert_select "[data-testid=team-show-name]", text: "Core Team"
    end

    should "be not found for an unknown handle" do
      get organization_team_path(@organization, "missing")

      assert_response :not_found
    end

    should "not show another organization's team under this organization" do
      other_organization = create(:organization)
      create(:membership, organization: other_organization, user: @user, role: :admin)
      enable_feature(FeatureFlag::ORGANIZATION_TEAMS, actor: other_organization)
      create(:organization_team, organization: other_organization, handle: "secret", name: "Secret Team")

      get organization_team_path(@organization, "secret")

      assert_response :not_found
    end

    should "be not found for a non-member" do
      sign_in_as(create(:user))

      get organization_team_path(@organization, @team)

      assert_response :not_found
    end

    should "redirect to sign in when signed out" do
      delete sign_out_path

      get organization_team_path(@organization, @team)

      assert_redirected_to sign_in_path
    end

    should "be not found when the feature is disabled for the organization" do
      disable_feature(FeatureFlag::ORGANIZATION_TEAMS)

      get organization_team_path(@organization, @team)

      assert_response :not_found
    end

    should "be linked from the team list with an arrow" do
      get organization_teams_path(@organization)

      assert_select "a[data-testid=team][href=?]", organization_team_path(@organization, @team) do
        assert_select "[data-testid=team-name]", text: "Core Team"
        assert_select "use[href$=?]", "#arrow-forward-ios"
      end
    end
  end

  context "organization navigation" do
    should "link to teams when the feature is enabled" do
      get organization_gems_path(@organization)

      assert_select "a[href=?]", organization_teams_path(@organization)
    end

    should "link to teams for a maintainer" do
      @membership.update!(role: :maintainer)

      get organization_path(@organization)

      assert_select "a[href=?]", organization_teams_path(@organization)
    end

    should "not link to teams for a non-member" do
      sign_in_as(create(:user))

      get organization_path(@organization)

      assert_response :success
      assert_select "a[href=?]", organization_teams_path(@organization), count: 0
    end

    should "not link to teams when signed out" do
      delete sign_out_path

      get organization_path(@organization)

      assert_response :success
      assert_select "a[href=?]", organization_teams_path(@organization), count: 0
    end

    should "not link to teams when the feature is disabled" do
      disable_feature(FeatureFlag::ORGANIZATION_TEAMS)

      get organization_gems_path(@organization)

      assert_select "a[href=?]", organization_teams_path(@organization), count: 0
    end
  end
end
