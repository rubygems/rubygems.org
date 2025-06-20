require "test_helper"

class Rubygems::Transfer::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    @rubygem = create(:rubygem, owners: [@user])
  end

  test "POST /rubygems/:rubygem_id/transfer/organization" do
    post rubygem_transfer_organization_path(@rubygem.slug, as: @user), params: { rubygem_transfer: { organization_handle: @organization.handle } }

    assert_response :redirect
    assert_redirected_to rubygem_transfer_users_path(@rubygem.slug)
  end

  test "POST /rubygems/:rubygem_id/transfer/organization with invalid organization" do
    post rubygem_transfer_organization_path(@rubygem.slug, as: @user), params: { rubygem_transfer: { organization_handle: "invalid_handle" } }

    assert_response :unprocessable_entity
  end
end
