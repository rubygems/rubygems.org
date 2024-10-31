require "test_helper"

class Organizations::MembersTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  test "index should render Not Found org" do
    get "/organizations/notfound/members"

    assert_response :not_found
  end

  test "index should render Forbidden" do
    create(:organization, handle: "chaos")

    get "/organizations/chaos/members"

    assert_response :forbidden
  end

  test "should get index" do
    create(:organization, owners: [@user], handle: "chaos")

    get "/organizations/chaos/members"

    assert_response :success
    assert page.has_content?("Members")
  end

  test "create should return Not Found org" do
    post "/organizations/notfound/members", params: { membership: { role: "owner" } }

    assert_response :not_found
  end

  test "create should return Forbidden when trying to create your own membership" do
    create(:organization, handle: "chaos")

    post "/organizations/chaos/members", params: { membership: { username: @user.id, role: "maintainer" } }

    assert_response :forbidden
  end

  test "create membership with bad role should not work" do
    organization = create(:organization, owners: [@user], handle: "chaos")
    bdfl = create(:user, handle: "bdfl")

    post "/organizations/chaos/members", params: { membership: { username: bdfl.handle, role: "bdfl" } }

    assert_redirected_to organization_members_path(organization)
    follow_redirect!

    assert page.has_content?("Failed to add member: Role is not included in the list")
    assert_nil organization.unconfirmed_memberships.find_by(user_id: bdfl.id)
  end

  test "create membership by email should not work (yet)" do
    organization = create(:organization, owners: [@user], handle: "chaos")
    maintainer = create(:user, handle: "maintainer")

    post "/organizations/chaos/members", params: { membership: { username: maintainer.email, role: "maintainer" } }

    assert_redirected_to organization_members_path(organization)
    follow_redirect!

    assert page.has_content?("Failed to add member: User not found")
    assert_nil organization.unconfirmed_memberships.find_by(user_id: maintainer.id)
  end

  test "should create a membership by handle" do
    organization = create(:organization, owners: [@user], handle: "chaos")
    maintainer = create(:user, handle: "maintainer")

    post "/organizations/chaos/members", params: { membership: { username: maintainer.handle, role: "maintainer" } }

    assert_redirected_to organization_members_path(organization)
    membership = organization.unconfirmed_memberships.find_by(user_id: maintainer.id)

    assert membership
    assert_predicate membership, :maintainer?
    refute_predicate membership, :confirmed?
  end

  test "update should return Not Found org" do
    patch "/organizations/notfound/members/notfound", params: { membership: { role: "owner" } }

    assert_response :not_found
  end

  test "update should return Not Found membership" do
    create(:organization, owners: [@user], handle: "chaos")

    patch "/organizations/chaos/members/notfound", params: { membership: { role: "owner" } }

    assert_response :not_found
  end

  test "update should return Forbidden" do
    organization = create(:organization, handle: "chaos")
    membership = create(:membership, :maintainer, user: @user, organization: organization)

    patch "/organizations/chaos/members/#{@user.handle}", params: { membership: { role: "owner" } }

    assert_response :forbidden
  end

  test "should update" do
    organization = create(:organization, owners: [@user], handle: "chaos")
    maintainer = create(:user, handle: "maintainer")
    membership = create(:membership, :maintainer, user: maintainer, organization: organization)

    patch "/organizations/chaos/members/#{maintainer.handle}", params: { membership: { role: "owner" } }

    assert_redirected_to organization_members_path(organization)
    assert_predicate membership.reload, :owner?
  end

  test "destroy should return Not Found org" do
    delete "/organizations/notfound/members/notfound"

    assert_response :not_found
  end

  test "destroy should return Not Found membership" do
    create(:organization, owners: [@user], handle: "chaos")

    delete "/organizations/chaos/members/notfound"

    assert_response :not_found
  end

  test "destroy should return Forbidden" do
    organization = create(:organization, handle: "chaos")
    membership = create(:membership, :maintainer, user: @user, organization: organization)

    delete "/organizations/chaos/members/#{@user.handle}"

    assert_response :forbidden
  end

  test "should destroy a membership" do
    organization = create(:organization, handle: "chaos", owners: [@user])
    maintainer = create(:user, handle: "maintainer")
    membership = create(:membership, :maintainer, user: maintainer, organization: organization)

    delete "/organizations/chaos/members/#{maintainer.handle}"

    assert_redirected_to organization_members_path(organization)
    assert_nil Membership.find_by(id: membership.id)
  end
end
