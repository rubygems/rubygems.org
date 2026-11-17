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

  def render_component(members: [], addable_memberships: [], can_manage: true)
    render Organizations::Teams::MembersComponent.new(team: @team, members:, addable_memberships:, can_manage:)
  end

  should "list members in the given order" do
    render_component(members: [member("carol"), member("alice")])

    assert_equal %w[carol alice], page.all("[data-testid=team-member-handle]").map(&:text)
  end

  should "show remove buttons and the picker when the viewer can manage" do
    carol = member("carol")
    render_component(members: [carol], addable_memberships: [member("dave")])

    assert_selector "[data-testid=remove-team-member]", count: 1
    assert_selector "form[action='/organizations/#{@organization.handle}/teams/#{@team.handle}/members/#{carol.id}']"
    assert_selector "[data-testid=add-team-members][action='/organizations/#{@organization.handle}/teams/#{@team.handle}/members']"
  end

  should "show neither remove buttons nor the picker when the viewer cannot manage" do
    render_component(members: [member("carol")], addable_memberships: [member("dave")], can_manage: false)

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
    render_component(members: [member("carol")])

    assert_no_selector "[data-testid=add-team-members]"
  end
end
