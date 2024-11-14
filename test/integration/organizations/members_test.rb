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

  test "create should return Forbidden" do
    create(:organization, handle: "chaos")

    post "/organizations/chaos/members", params: { membership: { user_id: @user.id, role: "maintainer" } }

    assert_response :forbidden
  end

  test "should create a membership" do
    organization = create(:organization, owners: [@user], handle: "chaos")
    maintainer = create(:user, handle: "maintainer")

    patch "/organizations/chaos/members/#{membership.id}", params: { membership: { user_id: maintainer.id, role: "maintainer" } }

    assert_redirected_to organization_members_path(organization)
    membership = organization.memberships.find_by(user_id: maintainer.id), :maintainer?

    assert_predicate membership, :maintainer?
    assert_predicete membership, :unconfirmed?
  end

  test "update should return Not Found org" do
    patch "/organizations/notfound/members/1", params: { membership: { role: "owner" } }

    assert_response :not_found
  end

  test "update should return Not Found membership" do
    create(:organization, owners: [@user], handle: "chaos")

    patch "/organizations/chaos/members/1", params: { membership: { role: "owner" } }

    assert_response :not_found
  end

  test "update should return Forbidden" do
    organization = create(:organization, handle: "chaos")
    membership = create(:membership, :maintainer, user: @user, organization: organization)

    patch "/organizations/chaos/members/#{membership.id}", params: { membership: { role: "owner" } }

    assert_response :forbidden
  end

  test "should update" do
    organization = create(:organization, owners: [@user], handle: "chaos")
    maintainer = create(:user, handle: "maintainer")
    membership = create(:membership, :maintainer, user: maintainer, organization: organization)

    patch "/organizations/chaos/members/#{membership.id}", params: { membership: { role: "owner" } }

    assert_redirected_to organization_members_path(organization)
    assert_predicate membership.reload, :owner?
  end

  test "destroy should return Not Found org" do
    delete "/organizations/notfound/members/1"

    assert_response :not_found
  end

  test "destroy should return Not Found membership" do
    create(:organization, owners: [@user], handle: "chaos")

    delete "/organizations/chaos/members/1"

    assert_response :not_found
  end

  test "destroy should return Forbidden" do
    organization = create(:organization, handle: "chaos")
    membership = create(:membership, :maintainer, user: @user, organization: organization)

    delete "/organizations/chaos/members/#{membership.id}"

    assert_response :forbidden
  end

  test "should destroy a membership" do
    organization = create(:organization, handle: "chaos", owners: [@user])
    maintainer = create(:user, handle: "maintainer")
    membership = create(:membership, :maintainer, user: maintainer, organization: organization)

    delete "/organizations/chaos/members/#{membership.id}"

    assert_redirected_to organization_members_path(organization)
    assert_nil Membership.find_by(id: membership.id)
  end
end
