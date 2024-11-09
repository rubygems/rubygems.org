require "test_helper"

class Organizations::Onboarding::UsersControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @other_users = create_list(:user, 2)
    @rubygem = create(:rubygem, owners: [@user, *@other_users])

    sign_in_as(@user)

    @organization_onboarding = create(
      :organization_onboarding,
      created_by: @user,
      rubygems: [@rubygem.id]
    )

    @invites = @organization_onboarding.invites.to_a
  end

  test "render the list of users to invite" do
    get :edit

    assert_response :ok
    # assert a text field has has the handle
    @invites.each_with_index do |invite, idx|
      assert_select "input[name='organization_onboarding[invites_attributes][#{idx}][id]'][value='#{invite.id}']"
      assert_select "select[name='organization_onboarding[invites_attributes][#{idx}][role]']"
    end
  end

  test "should update invites ignoring blank rows" do
    patch :update, params: {
      organization_onboarding: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "maintainer" },
          "1" => { id: @invites[1].id, role: "" }
        }
      }
    }

    assert_redirected_to organization_onboarding_confirm_path

    @organization_onboarding.reload

    assert_equal "maintainer", @organization_onboarding.invites.find_by(user_id: @other_users[0].id).role
    assert_equal "", @organization_onboarding.invites.find_by(user_id: @other_users[1].id).role
  end

  test "should update multiple users" do
    patch :update, params: {
      organization_onboarding: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "maintainer" },
          "1" => { id: @invites[1].id, role: "admin" }
        }
      }
    }

    assert_redirected_to organization_onboarding_confirm_path

    @organization_onboarding.reload

    assert_equal "maintainer", @organization_onboarding.invites.find_by(user_id: @other_users[0].id).role
    assert_equal "admin", @organization_onboarding.invites.find_by(user_id: @other_users[1].id).role
  end

  test "should update users including existing invites" do
    patch :update, params: {
      organization_onboarding: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "admin" },
          "1" => { id: @invites[1].id, role: "maintainer" }
        }
      }
    }

    @organization_onboarding.reload

    assert_redirected_to organization_onboarding_confirm_path
    assert_equal "admin", @organization_onboarding.invites.find_by(user_id: @other_users[0].id).role
    assert_equal "maintainer", @organization_onboarding.invites.find_by(user_id: @other_users[1].id).role

    get :edit

    assert_select "input[name='organization_onboarding[invites_attributes][0][id]'][value='#{@invites[0].id}']"
    assert_select "select[name='organization_onboarding[invites_attributes][0][role]'] option[selected][value='admin']"
    assert_select "input[name='organization_onboarding[invites_attributes][1][id]'][value='#{@invites[1].id}']"
    assert_select "select[name='organization_onboarding[invites_attributes][1][role]'] option[selected][value='maintainer']"

    patch :update, params: {
      organization_onboarding: {
        invites_attributes: {
          "0" => { id: @invites[0].id, role: "maintainer" },
          "1" => { id: @invites[1].id, role: "" }
        }
      }
    }

    @organization_onboarding.reload

    assert_equal "maintainer", @organization_onboarding.invites.find_by(user_id: @other_users[0].id).role
    assert_equal "", @organization_onboarding.invites.find_by(user_id: @other_users[1].id).role
  end
end
