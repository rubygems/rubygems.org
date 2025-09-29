require "test_helper"

class Rubygems::Transfer::RubygemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    @rubygem = create(:rubygem, owners: [@user])
    @rubygem_transfer = create(:rubygem_transfer, organization: @organization, created_by: @user, status: :pending, rubygems: [])
  end

  test "GET /rubygems/transfer/rubygems" do
    get rubygems_transfer_rubygems_path(as: @user)

    assert_response :success
  end

  test "PATCH /rubygems/transfer/rubygems" do
    patch rubygems_transfer_rubygems_path(as: @user), params: { rubygem_transfer: { rubygems: [@rubygem.id] } }

    assert_response :redirect
    assert_redirected_to users_transfer_rubygems_path
    assert_includes @rubygem_transfer.reload.rubygems, @rubygem.id
  end

  test "PATCH /rubygems/transfer/rubygems with unowned gem" do
    other_gem = create(:rubygem)
    patch rubygems_transfer_rubygems_path(as: @user), params: { rubygem_transfer: { rubygems: [other_gem.id] } }

    assert_response :unprocessable_content
  end
end
