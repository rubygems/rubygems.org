require "test_helper"

class Rubygems::Transfer::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user)
    @maintainers = create_list(:user, 2)
    @organization = create(:organization)
    @rubygem = create(:rubygem, owners: [@owner], maintainers: @maintainers)

    @transfer = create(:rubygem_transfer, rubygems: [@rubygem.id], organization: @organization, created_by: @owner)
    @invites = @transfer.invites.to_a
  end

  test "PATCH /rubygems/:rubygem_id/transfer/users" do
    patch users_transfer_rubygems_path(as: @owner), params: {
      rubygem_transfer: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "maintainer" },
          "1" => { id: @invites[1].id, role: "" }
        }
      }
    }

    assert_equal "maintainer", @invites[0].reload.role
    assert_nil @invites[1].reload.role

    assert_response :redirect
    assert_redirected_to confirm_transfer_rubygems_path
  end

  test "PATCH /rubygems/:rubygem_id/transfer/users without any invite attributes" do
    patch users_transfer_rubygems_path(as: @owner), params: {}

    assert_response :redirect
    assert_redirected_to confirm_transfer_rubygems_path
  end

  test "POST /rubygems/:rubygem_id/transfer/users with invalid role" do
    patch users_transfer_rubygems_path(as: @owner), params: {
      rubygem_transfer: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "invalid_role" }
        }
      }
    }

    assert_response :unprocessable_content
  end

  test "PATCH /rubygems/:rubygem_id/transfer/users with outside contributor role" do
    patch users_transfer_rubygems_path(as: @owner), params: {
      rubygem_transfer: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "outside_contributor" },
          "1" => { id: @invites[1].id, role: "maintainer" }
        }
      }
    }

    assert_equal "outside_contributor", @invites[0].reload.role
    assert_equal "maintainer", @invites[1].reload.role

    assert_response :redirect
    assert_redirected_to confirm_transfer_rubygems_path
  end
end
