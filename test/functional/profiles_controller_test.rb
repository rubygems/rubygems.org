require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase

  context "when logged in" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end

    context "on GET to show with handle" do
      setup {get :show, :id => @user.handle}

      should respond_with :success
      should render_template :show
    end

    context "on GET to show with id" do
      setup {get :show, :id => @user.id}

      should respond_with :success
      should render_template :show
    end

    context "on GET to edit" do
      setup { get :edit }

      should respond_with :success
      should render_template :edit
    end

    context "on PUT to update" do
      context "updating handle" do
        setup do
          @handle = "john_m_doe"
          @user = Factory(:email_confirmed_user, :handle => "johndoe")
          sign_in_as(@user)
          put :update, :user => {:handle => @handle}
        end

        should respond_with :redirect
        should redirect_to('the profile edit page') { edit_profile_path }
        should set_the_flash.to("Your profile was updated.")

        should "update handle" do
          assert_equal @handle, User.last.handle
        end
      end
    end
  end

  context "On GET to edit without being signed in" do
    setup { get :edit }
    should respond_with :redirect
    should redirect_to('the homepage') { root_url }
  end

end

