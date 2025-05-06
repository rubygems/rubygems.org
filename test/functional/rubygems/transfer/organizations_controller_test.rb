require "test_helper"

class Rubygems::Transfer::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    @rubygem = create(:rubygem, owners: [@user])
  end

  test "POST /rubygems/:rubygem_id/transfer/organization" do
    post rubygem_transfer_organization_path(@rubygem.slug, as: @user), params: { organization_id: @organization.id }

    assert_response :success
  end
end
