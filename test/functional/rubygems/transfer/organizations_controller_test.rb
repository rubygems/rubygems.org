require "test_helper"

class Rubygems::Transfer::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    @rubygem = create(:rubygem, owners: [@user])
  end

  test "GET /rubygems/:rubygem_id/transfer/organization" do
    get rubygem_transfer_organization_path(@rubygem.slug, as: @user)

    assert_response :success
  end

  test "GET /rubygems/:rubygem_id/transfer/organization with existing rubygems transfer" do
    transfer = create(:rubygem_transfer, rubygem: @rubygem, organization: @organization, created_by: @user, status: :pending)

    get rubygem_transfer_organization_path(@rubygem.slug, as: @user)

    assert_response :success
    assert_select "select[name=?] option[selected=selected][value=?]", "rubygem_transfer[organization]", transfer.organization.handle
  end

  test "POST /rubygems/:rubygem_id/transfer/organization" do
    post rubygem_transfer_organization_path(@rubygem.slug, as: @user), params: { rubygem_transfer: { organization: @organization.handle } }

    assert RubygemTransfer.exists?(rubygem: @rubygem, organization: @organization, created_by: @user, status: :pending)

    assert_response :redirect
    assert_redirected_to rubygem_transfer_users_path(@rubygem.slug)
  end

  test "POST /rubygems/:rubygem_id/transfer/organization with non-owner user" do
    non_owner = create(:user)
    post rubygem_transfer_organization_path(@rubygem.slug, as: non_owner), params: { rubygem_transfer: { organization: @organization.handle } }

    assert_response :not_found
  end

  test "POST /rubygems/:rubygem_id/transfer/organization with invalid organization" do
    post rubygem_transfer_organization_path(@rubygem.slug, as: @user), params: { rubygem_transfer: { organization: "invalid_handle" } }

    assert_response :unprocessable_content
  end
end
