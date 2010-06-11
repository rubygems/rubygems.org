require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase

  context "when logged in" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end

    context "on GET to edit" do
      setup do
        get :edit
      end

      should_respond_with :success
      should_render_template :edit
      should_assign_to(:user) { @user }
    end

    context "on PUT to update" do
      context "updating handle" do
        setup do
          @handle = "john_m_doe"
          @user = Factory(:email_confirmed_user, :handle => "johndoe")
          sign_in_as(@user)
          put :update, :user => {:handle => @handle}
        end

        should_respond_with :redirect
        should_redirect_to('the profile') { profile_path }
        should_set_the_flash_to "Your profile was updated."
        should_assign_to(:user) { @user }

        should "update handle" do
          assert_equal @handle, User.last.handle
        end
      end
    end
  end

  context "On GET to edit without being signed in" do
    setup { get :edit }
    should_respond_with :redirect
    should_redirect_to('the homepage') { root_url }
  end

end

