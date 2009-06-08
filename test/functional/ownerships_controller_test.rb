require 'test_helper'

class OwnershipsControllerTest < ActionController::TestCase

  context "with a rubygem" do
    setup do
      @rubygem = Factory(:rubygem)
      @user = Factory(:email_confirmed_user)
    end

    context "On GET to show without being signed in" do
      setup do
        @ownership = Factory(:ownership, :rubygem => @rubygem, :user => @user)
        get :show, :rubygem_id => @rubygem.to_param, :id => @ownership.to_param
      end
      should_respond_with :redirect
      should_redirect_to('the homepage') { root_url }
    end

    context "When logged in" do
      setup do
        sign_in_as(@user)
      end

      context "On GET to show" do
        setup do
          @ownership = Factory(:ownership, :rubygem => @rubygem, :user => @user)
          get :show, :rubygem_id => @rubygem.to_param, :id => @ownership.to_param
        end
        should_respond_with :success
        should "render show" do
          assert_equal @ownership.token, @response.body
          assert_equal "text/plain", @response.content_type
        end
      end
    end
  end
end
