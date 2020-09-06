require "test_helper"

class Api::V1::OwnerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @other_user = create(:user)
    cookies[:remember_token] = @user.remember_token

    @rubygem = create(:rubygem, number: "1.0.0")
    create(:ownership, user: @user, rubygem: @rubygem)
  end

  test "adding an owner" do
    post api_v1_rubygem_owners_path(@rubygem),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @user.api_key }
    assert_response :success

    @ownership = @rubygem.ownerships_including_unconfirmed.find_by(user: @other_user)
    get confirm_rubygem_owners_url(@rubygem, token: @ownership.token)

    get rubygem_path(@rubygem)
    assert page.has_selector?("a[alt='#{@user.handle}']")
    assert page.has_selector?("a[alt='#{@other_user.handle}']")
  end

  test "removing an owner" do
    create(:ownership, user: @other_user, rubygem: @rubygem)
    delete api_v1_rubygem_owners_path(@rubygem),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @user.api_key }

    get rubygem_path(@rubygem)
    assert page.has_selector?("a[alt='#{@user.handle}']")
    refute page.has_selector?("a[alt='#{@other_user.handle}']")
  end

  test "transferring ownership" do
    create(:ownership, user: @other_user, rubygem: @rubygem)

    delete api_v1_rubygem_owners_path(@rubygem),
      params: { email: @user.email },
      headers: { "HTTP_AUTHORIZATION" => @user.api_key }

    get rubygem_path(@rubygem)
    refute page.has_selector?("a[alt='#{@user.handle}']")
    assert page.has_selector?("a[alt='#{@other_user.handle}']")
  end

  test "adding ownership without permission" do
    post api_v1_rubygem_owners_path(@rubygem),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @other_user.api_key }
    assert_response :unauthorized

    delete api_v1_rubygem_owners_path(@rubygem),
      params: { email: @other_user.email },
      headers: { "HTTP_AUTHORIZATION" => @other_user.api_key }
    assert_response :unauthorized
  end
end
