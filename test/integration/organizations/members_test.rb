require "test_helper"

class Organizations::MembersTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    @maintainer = create(:user)
    @organization = create(:organization)

    @owner_membership = create(:membership, user: @owner, organization: @organization, role: "owner")
    @maintainer_membership = create(:membership, user: @maintainer, organization: @organization, role: "maintainer")
  end

  should "get index as a guest user" do
    get organization_memberships_path(@organization)

    assert_response :success
    assert_select "h1", text: "Members"
    assert_select "a", text: "Invite", count: 0
    assert_select "li a[href=?]", profile_path(@owner), text: @owner.handle
    assert_select "li a[href=?]", profile_path(@maintainer), text: @maintainer.handle
  end

  should "get index as an owner" do
    post session_path(session: { who: @owner.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get organization_memberships_path(@organization)

    assert_response :success
    assert_select "h1", text: "Members"
    assert_select "a", text: "Invite", count: 1
    assert_select "li a[href=?]", edit_organization_membership_path(@organization, @owner_membership), text: "#{@owner.handle} owner"
    assert_select "li a[href=?]", edit_organization_membership_path(@organization, @maintainer_membership), text: "#{@maintainer.handle} maintainer"
  end
end
