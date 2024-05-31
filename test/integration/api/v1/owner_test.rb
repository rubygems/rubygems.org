require "test_helper"

class Api::V1::OwnerTest < ActionDispatch::IntegrationTest
  setup do
    @user_api_key = "12323"
    @user = create(:api_key, key: @user_api_key, scopes: %i[add_owner remove_owner]).user

    @other_user_api_key = "12324"
    @other_user = create(:api_key, key: @other_user_api_key, scopes: %i[add_owner remove_owner]).user
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    @trusted_publisher_api_key = "12325"
    @trusted_publisher = create(:oidc_trusted_publisher_github_action)
    create(:api_key, key: @trusted_publisher_api_key, owner: @trusted_publisher)

    @rubygem = create(:rubygem, number: "1.0.0")
    create(:ownership, user: @user, rubygem: @rubygem)
  end

  test "adding an owner" do
    post api_v1_rubygem_owners_path(@rubygem.slug),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @user_api_key }

    assert_response :success

    @ownership = @rubygem.ownerships_including_unconfirmed.find_by(user: @other_user)
    get confirm_rubygem_owners_url(@rubygem.slug, token: @ownership.token)

    get rubygem_path(@rubygem.slug)

    assert page.has_selector?("a[alt='#{@user.handle}']")
    assert page.has_selector?("a[alt='#{@other_user.handle}']")
  end

  test "removing an owner" do
    create(:ownership, user: @other_user, rubygem: @rubygem)
    delete api_v1_rubygem_owners_path(@rubygem.slug),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @user_api_key }

    get rubygem_path(@rubygem.slug)

    assert page.has_selector?("a[alt='#{@user.handle}']")
    refute page.has_selector?("a[alt='#{@other_user.handle}']")
  end

  test "transferring ownership" do
    create(:ownership, user: @other_user, rubygem: @rubygem)

    delete api_v1_rubygem_owners_path(@rubygem.slug),
      params: { email: @user.email },
      headers: { "HTTP_AUTHORIZATION" => @user_api_key }

    get rubygem_path(@rubygem.slug)

    refute page.has_selector?("a[alt='#{@user.handle}']")
    assert page.has_selector?("a[alt='#{@other_user.handle}']")
  end

  test "adding ownership without permission" do
    post api_v1_rubygem_owners_path(@rubygem.slug),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @other_user_api_key }

    assert_response :unauthorized

    delete api_v1_rubygem_owners_path(@rubygem.slug),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @other_user_api_key }

    assert_response :unauthorized

    post api_v1_rubygem_owners_path(@rubygem.slug),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @trusted_publisher_api_key }

    assert_response :forbidden

    delete api_v1_rubygem_owners_path(@rubygem.slug),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @trusted_publisher_api_key }

    assert_response :forbidden
  end
end
