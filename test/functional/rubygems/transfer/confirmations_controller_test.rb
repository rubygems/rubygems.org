require "test_helper"

class Rubygems::Transfer::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user)
    @maintainers = create_list(:user, 2)
    @organization = create(:organization)
    @rubygem = create(:rubygem, maintainers: @maintainers)

    @transfer = create(:rubygem_transfer, rubygems: [@rubygem.id], organization: @organization, created_by: @owner)
  end

  test "PATCH /rubygems/:rubygem_id/transfer/confirm" do
    patch confirm_transfer_rubygems_path(as: @owner)

    assert_response :redirect
    assert_redirected_to organization_path(@organization.handle)
    assert_equal flash[:notice], "Successfully transferred 1 gem to #{@organization.name}."
  end

  test "PATCH /rubygems/:rubygem_id/transfer/confirm when transfer is invalid" do
    error_message = "Sorry"
    # cause transferring to fail
    RubygemTransfer.any_instance.stubs(:update!).raises(ActiveRecord::ActiveRecordError, error_message)

    patch confirm_transfer_rubygems_path(as: @owner)

    assert_response :unprocessable_content
    assert_equal flash[:error], "Onboarding error: #{error_message}"
  end

  test "PATCH /rubygems/:rubygem_id/transfer/confirm with a different user redirects to start transfer flow" do
    different_user = create(:user)

    patch confirm_transfer_rubygems_path(as: different_user)

    assert_response :redirect
    assert_redirected_to organization_transfer_rubygems_path
  end

  test "GET /rubygems/transfer/confirm redirects when organization is nil" do
    @transfer.update_column(:organization_id, nil)

    get confirm_transfer_rubygems_path(as: @owner)

    assert_response :redirect
    assert_redirected_to organization_transfer_rubygems_path
  end

  test "PATCH /rubygems/transfer/confirm redirects when organization is nil" do
    @transfer.update_column(:organization_id, nil)

    patch confirm_transfer_rubygems_path(as: @owner)

    assert_response :redirect
    assert_redirected_to organization_transfer_rubygems_path
  end

  test "GET /rubygems/transfer/confirm redirects when no rubygems selected" do
    @transfer.update_column(:rubygems, [])

    get confirm_transfer_rubygems_path(as: @owner)

    assert_response :redirect
    assert_redirected_to organization_transfer_rubygems_path
  end

  test "PATCH /rubygems/transfer/confirm redirects when no rubygems selected" do
    @transfer.update_column(:rubygems, [])

    patch confirm_transfer_rubygems_path(as: @owner)

    assert_response :redirect
    assert_redirected_to organization_transfer_rubygems_path
  end
end
