require "test_helper"

class Rubygems::Transfer::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @other_users = create_list(:user, 2)
    @organization = create(:organization, owners: [@user])
    @rubygem = create(:rubygem, owners: [@user], maintainers: @other_users)

    @transfer = create(:rubygem_transfer, rubygem: @rubygem, organization: @organization, created_by: @user)
    @invites = @transfer.invites.to_a
  end

  test "PATCH /rubygems/:rubygem_id/transfer/users" do
    patch rubygem_transfer_users_path(@rubygem.slug, as: @user), params: {
      rubygem_transfer: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "maintainer" },
          "1" => { id: @invites[1].id, role: "" }
        }
      }
    }

    assert_equal "maintainer", @transfer.invites.find_by(user_id: @other_users[0].id).role
    assert_nil @transfer.invites.find_by(user_id: @other_users[1].id).role

    assert_response :redirect
    assert_redirected_to rubygem_transfer_confirm_path(@rubygem.slug)
  end

  test "POST /rubygems/:rubygem_id/transfer/users with invalid role" do
    patch rubygem_transfer_users_path(@rubygem.slug, as: @user), params: {
      rubygem_transfer: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "invalid_role" }
        }
      }
    }

    assert_response :unprocessable_entity
  end
end
