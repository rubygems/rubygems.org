# frozen_string_literal: true

require "test_helper"

class Organizations::Teams::MembersComponentTest < ComponentTest
  setup do
    @team = create(:organization_team)
    @organization = @team.organization
  end

  def member(handle, **user_attributes)
    create(:membership, organization: @organization, user: create(:user, handle:, **user_attributes))
  end

  def on_team(handle, **user_attributes)
    @team.team_memberships.create!(membership: member(handle, **user_attributes))
  end

  def render_component(team_memberships: [], addable_memberships: [], can_manage: true)
    render Organizations::Teams::MembersComponent.new(team: @team, team_memberships:, addable_memberships:, can_manage:)
  end

  should "list members in the given order" do
    render_component(team_memberships: [on_team("carol"), on_team("alice")])

    assert_equal %w[carol alice], page.all("[data-testid=team-member-handle]").map(&:text)
  end

  should "show members in a table with handle, name, email and date added columns" do
    travel_to Time.zone.local(2026, 11, 18, 10) do
      @row = on_team("carol", full_name: "Carol Danvers", public_email: true)
    end
    render_component(team_memberships: [@row])

    assert_equal %w[Handle Name Email Added], page.all("[data-testid=team-members-table] thead th").map(&:text).first(4)
    within_row = page.find("[data-testid=team-member]")

    assert_equal "carol", within_row.find("[data-testid=team-member-handle]").text
    assert_equal "Carol Danvers", within_row.find("[data-testid=team-member-name]").text
    assert_equal @row.membership.user.email, within_row.find("[data-testid=team-member-email]").text
    assert_equal "November 18, 2026", within_row.find("[data-testid=team-member-added]").text
    assert_equal "2026-11-18", within_row.find("[data-testid=team-member-added] time")["datetime"]
  end

  should "leave the email cell empty when the email is private" do
    row = on_team("gina", public_email: false, full_name: nil)
    html = render_component(team_memberships: [row])

    assert_equal "", page.find("[data-testid=team-member-email]").text
    assert_equal "", page.find("[data-testid=team-member-name]").text
    refute_includes html, row.membership.user.email
  end

  should "show remove buttons and the picker when the viewer can manage" do
    carol = on_team("carol")
    render_component(team_memberships: [carol], addable_memberships: [member("dave")])

    assert_selector "[data-testid=remove-team-member]", count: 1
    assert_selector "form[action='/organizations/#{@organization.handle}/teams/#{@team.handle}/members/#{carol.membership.id}']"
    assert_selector "[data-testid=add-team-members][action='/organizations/#{@organization.handle}/teams/#{@team.handle}/members']"
  end

  should "show neither remove buttons nor the picker when the viewer cannot manage" do
    render_component(team_memberships: [on_team("carol")], addable_memberships: [member("dave")], can_manage: false)

    assert_selector "[data-testid=team-member]", count: 1
    assert_no_selector "[data-testid=remove-team-member]"
    assert_no_selector "[data-testid=add-team-members]"
  end

  should "show an empty state with no members" do
    render_component

    assert_selector "[data-testid=team-members-empty]"
    assert_no_selector "[data-testid=team-member]"
  end

  should "render one checkbox per addable membership with its id" do
    dave = member("dave", full_name: "Dave Kim")
    erin = member("erin")
    render_component(addable_memberships: [dave, erin])

    values = page.all("[data-testid=add-member-option] input[type=checkbox][name='membership_ids[]']").map(&:value)

    assert_equal [dave.id.to_s, erin.id.to_s], values
    assert_text "Dave Kim"
  end

  should "show a public email" do
    dave = member("dave", public_email: true)
    render_component(addable_memberships: [dave])

    assert_text dave.user.email
  end

  should "hide private email" do
    gina = member("gina", public_email: false, full_name: nil)
    html = render_component(addable_memberships: [gina])

    assert_equal "gina", page.find("[data-testid=add-member-option]").text.strip
    refute_includes html, gina.user.email
  end

  should "omit the picker when no memberships are addable" do
    render_component(team_memberships: [on_team("carol")])

    assert_no_selector "[data-testid=add-team-members]"
  end
end
