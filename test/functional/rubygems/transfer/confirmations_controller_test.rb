require "test_helper"

class Rubygems::Transfer::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @other_users = create_list(:user, 2)
    @organization = create(:organization)
    @rubygem = create(:rubygem, maintainers: @other_users)

    @transfer = create(:rubygem_transfer, rubygem: @rubygem, organization: @organization, created_by: @user)
  end

  test "PATCH /rubygems/:rubygem_id/transfer/confirm" do
    patch rubygem_transfer_confirm_path(@rubygem.slug, as: @user)

    assert_response :redirect
    assert_redirected_to rubygem_path(@rubygem.slug)
    assert_equal flash[:notice], "#{@rubygem.name} has been transferred successfully to #{@organization.name}."
  end

  test "PATCH /rubygems/:rubygem_id/transfer/confirm when transfer is invalid" do
    error_message = "Sorry"
    # cause transferring to fail
    RubygemTransfer.any_instance.stubs(:update!).raises(ActiveRecord::ActiveRecordError, error_message)

    patch rubygem_transfer_confirm_path(@rubygem.slug, as: @user)

    assert_response :unprocessable_content
    assert_equal flash[:error], "Onboarding error: #{error_message}"
  end

  test "PATCH /rubygems/:rubygem_id/transfer/confirm with an unauthorized user" do
    unauthorized_user = create(:user)

    patch rubygem_transfer_confirm_path(@rubygem.slug, as: unauthorized_user)

    assert_response :not_found
  end
end
