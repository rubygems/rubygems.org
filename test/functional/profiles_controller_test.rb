require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase

  context "for a user that doesn't exist" do
    should "throw a not found" do
      assert_raise ActiveRecord::RecordNotFound do
        get :show, :id => "unknown"
      end
    end
  end

  context "when logged in" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end

    context "on GET to show" do
      setup do
        @rubygems = (0..10).map do |n|
          Factory(:rubygem, :downloads => n * 100).tap do |rubygem|
            Factory(:ownership, :rubygem => rubygem, :user => @user, :approved => true)
          end
        end.reverse

        get :show, :id => @user.handle
      end

      should respond_with :success
      should render_template :show
      should assign_to(:user) { @user }
      should "assign the last 10 most downloaded gems" do
        assert_equal @rubygems[0..9], assigns[:rubygems]
      end
      should "assign the extra gems you own" do
        assert_equal [@rubygems.last], assigns[:extra_rubygems]
      end
    end

    context "on GET to show with handle" do
      setup do
        get :show, :id => @user.handle
      end

      should respond_with :success
      should render_template :show
      should assign_to(:user) { @user }
    end

    context "on GET to show with id" do
      setup {get :show, :id => @user.id}

      should respond_with :success
      should render_template :show
      should assign_to(:user) { @user }
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
