require "test_helper"

class Rubygems::Transfer::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    @rubygem = create(:rubygem, owners: [@user])

    @transfer = create(:rubygem_transfer, rubygem: @rubygem, created_by: @user)
  end

  test "POST /rubygems/:rubygem_id/transfer/users" do
    post rubygem_transfer_organization_path(@rubygem.slug, as: @user), params: { rubygem_transfer: { organization_handle: @organization.handle } }

    assert_response :redirect
    assert_redirected_to rubygem_transfer_users_path(@rubygem.slug)
  end
end
