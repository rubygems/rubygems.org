require "test_helper"

class Rubygems::Transfer::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    @rubygem = create(:rubygem, owners: [@user])
  end

  test "GET /rubygems/transfer/organization" do
    get organization_transfer_rubygems_path(as: @user)

    assert_response :success
  end

  test "GET /rubygems/transfer/organization with existing rubygems transfer" do
    transfer = create(:rubygem_transfer, organization: @organization, created_by: @user, status: :pending)

    get organization_transfer_rubygems_path(as: @user)

    assert_response :success
    assert_select "select[name=?] option[selected=selected][value=?]", "rubygem_transfer[organization]", transfer.organization.handle
  end

  test "POST /rubygems/transfer/organization" do
    post organization_transfer_rubygems_path(as: @user), params: { rubygem_transfer: { organization: @organization.handle } }

    assert RubygemTransfer.exists?(organization: @organization, created_by: @user, status: :pending)

    assert_response :redirect
    assert_redirected_to rubygems_transfer_rubygems_path
  end

  test "POST /rubygems/transfer/organization with non-owner user" do
    non_owner = create(:user)
    post organization_transfer_rubygems_path(as: non_owner), params: { rubygem_transfer: { organization: @organization.handle } }

    assert_response :unprocessable_content
  end

  test "POST /rubygems/transfer/organization with invalid organization" do
    post organization_transfer_rubygems_path(as: @user), params: { rubygem_transfer: { organization: "invalid_handle" } }

    assert_response :unprocessable_content
  end
end
