require "test_helper"

class Organizations::Onboarding::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :mfa_enabled)
    @other_users = create_list(:user, 2)
    @rubygem = create(:rubygem, owners: [@user, *@other_users])

    @organization_onboarding = create(
      :organization_onboarding,
      created_by: @user,
      namesake_rubygem: @rubygem
    )

    @invites = @organization_onboarding.invites.to_a
  end

  context "on GET /organizations/onboarding/users" do
    should "render the list of users to invite" do
      get organization_onboarding_users_path(as: @user)

      assert_response :ok
      # assert a text field has the handle
      @invites.each_with_index do |invite, idx|
        assert_select "input[name='organization_onboarding[invites_attributes][#{idx}][id]'][value='#{invite.id}']"
        assert_select "select[name='organization_onboarding[invites_attributes][#{idx}][role]']"
      end
    end

    context "when there are already users added" do
      should "render the list of users with their roles" do
        @organization_onboarding.invites.where(user_id: @other_users[0].id).update!(role: "admin")
        @organization_onboarding.invites.where(user_id: @other_users[1].id).update!(role: "maintainer")

        get organization_onboarding_users_path(as: @user)

        assert_response :ok

        assert_select "input[name='organization_onboarding[invites_attributes][0][id]'][value='#{@invites[0].id}']"
        assert_select "select[name='organization_onboarding[invites_attributes][0][role]'] option[selected][value='admin']"
        assert_select "input[name='organization_onboarding[invites_attributes][1][id]'][value='#{@invites[1].id}']"
        assert_select "select[name='organization_onboarding[invites_attributes][1][role]'] option[selected][value='maintainer']"
      end
    end
  end

  context "on PATCH /organizations/onboarding/users" do
    should "update invites ignoring blank rows" do
      patch organization_onboarding_users_path(as: @user), params: {
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
      assert_nil @organization_onboarding.invites.find_by(user_id: @other_users[1].id).role
    end

    should "update invites ignoring user_id in invites_attributes" do
      patch organization_onboarding_users_path(as: @user), params: {
        organization_onboarding: {
          invites_attributes: {
            "0" => { id: @invites[0].id, role: "maintainer" },
            "1" => { user_id: @invites[1].user.id, role: "owner" }
          }
        }
      }

      assert_redirected_to organization_onboarding_confirm_path

      @organization_onboarding.reload

      assert_equal "maintainer", @organization_onboarding.invites.find_by(user_id: @other_users[0].id).role
      assert_nil @organization_onboarding.invites.find_by(user_id: @other_users[1].id).role
      assert_equal 1, @organization_onboarding.approved_invites.count
    end

    should "update multiple users" do
      patch organization_onboarding_users_path(as: @user), params: {
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

    context "when already invited users" do
      should "update roles and/or uninvite" do
        @organization_onboarding.invites.create(user_id: @other_users[0].id, role: "admin")
        @organization_onboarding.invites.create(user_id: @other_users[1].id, role: "maintainer")

        patch organization_onboarding_users_path(as: @user), params: {
          organization_onboarding: {
            invites_attributes: {
              "0" => { id: @invites[0].id, role: "maintainer" },
              "1" => { id: @invites[1].id, role: "" }
            }
          }
        }

        @organization_onboarding.reload

        assert_equal "maintainer", @organization_onboarding.invites.find_by(user_id: @other_users[0].id).role
        assert_nil @organization_onboarding.invites.find_by(user_id: @other_users[1].id).role
      end
    end
  end
end
