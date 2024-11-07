require "test_helper"

class Onboarding::UsersControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @other_users = create_list(:user, 2)
    @gem = create(:rubygem, owners: [@user, *@other_users])

    sign_in_as(@user)

    @organization_onboarding = create(:organization_onboarding, created_by: @user, status: :pending)
  end

  test "render the list of users to invite" do
    get :edit

    assert_response :ok
    # assert a text field has has the handle
    @other_users.each_with_index do |user, idx|
      assert_select "input[name='organization_onboarding[invites_attributes][#{idx}][user_id]'][value='#{user.id}']"
      assert_select "select[name='organization_onboarding[invites_attributes][#{idx}][role]']"
    end
  end

  test "should update invites ignoring blank rows" do
    patch :update, params: {
      organization_onboarding: {
        invites_attributes: {
          "0" => { user_id: @other_users[0].id, role: "maintainer" },
          "1" => { user_id: @other_users[1].id, role: "" }
        }
      }
    }

    assert_redirected_to onboarding_confirm_path

    @organization_onboarding.reload

    assert_predicate @organization_onboarding.invites.find_by(user_id: @other_users[0].id), :maintainer?
    assert_nil @organization_onboarding.invites.find_by(user_id: @other_users[1].id)
  end

  test "should update multiple users" do
    patch :update, params: {
      organization_onboarding: {
        invites_attributes: {
          "0" => { user_id: @other_users[0].id, role: "maintainer" },
          "1" => { user_id: @other_users[1].id, role: "admin" }
        }
      }
    }

    assert_redirected_to onboarding_confirm_path

    @organization_onboarding.reload

    assert_predicate @organization_onboarding.invites.find_by(user_id: @other_users[0].id), :maintainer?
    assert_predicate @organization_onboarding.invites.find_by(user_id: @other_users[1].id), :admin?
  end

  test "should update users including existing invites" do
    patch :update, params: {
      organization_onboarding: {
        invites_attributes: {
          "0" => { user_id: @other_users[0].id, role: "admin" },
          "1" => { user_id: @other_users[1].id, role: "maintainer" }
        }
      }
    }

    @organization_onboarding.reload

    assert_redirected_to onboarding_confirm_path
    assert_predicate @organization_onboarding.invites.find_by(user_id: @other_users[0].id), :admin?
    assert_predicate @organization_onboarding.invites.find_by(user_id: @other_users[1].id), :maintainer?

    get :edit

    assert_select "input[name='organization_onboarding[invites_attributes][0][user_id]'][value='#{@other_users[1].id}']"
    assert_select "select[name='organization_onboarding[invites_attributes][0][role]'][value='admin']"

    patch :update, params: {
      organization_onboarding: {
        invites_attributes: {
          "0" => { user_id: @other_users[0].id, role: "maintainer" },
          "1" => { user_id: @other_users[1].id, role: "" }
        }
      }
    }

    @organization_onboarding.reload

    assert_predicate @organization_onboarding.invites.find_by(user_id: @other_users[0].id), :maintainer?
    assert_nil @organization_onboarding.invites.find_by(user_id: @other_users[1].id)
  end
end
