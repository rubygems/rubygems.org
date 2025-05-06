require "test_helper"

class Rubygems::TransferControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "example_gem", owners: [@user])
    @rubygem_transfer = create(:rubygem_transfer, created_by: @user, rubygem: @rubygem, status: :pending)
  end

  test "DELETE /rubygems/transfer" do
    delete rubygem_transfer_path(@rubygem.slug, as: @user)

    assert_response :redirect
    assert_redirected_to rubygem_path(@rubygem.slug)
  end
end
