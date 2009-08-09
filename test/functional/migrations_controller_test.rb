require 'test_helper'

class MigrationsControllerTest < ActionController::TestCase
  context "with a rubygem" do
    setup do
      @rubygem = Factory(:rubygem)
    end
    should_forbid_access_when("starting the migration") { post :create, :rubygem_id => @rubygem }
  end

  context "with a confirmed user authenticated" do
    setup do
      @user = Factory(:email_confirmed_user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    should "respond with 404 if no rubygem is found" do
      Rubygem.delete(1)
      post :create, :rubygem_id => 1
      assert_response :not_found
    end

    should "respond with a 403 if the gem is already owned" do
      other_user = Factory(:email_confirmed_user)
      create_gem(other_user)
      post :create, :rubygem_id => @gem.id
      assert_response :forbidden
    end

    should "render the ownership token if the migration has not been completed" do
      rubygem = Factory(:rubygem)
      post :create, :rubygem_id => rubygem.id
      assert_response :success
      assert_equal Ownership.last.token, @response.body
    end

    should "not create another ownership if migration is started again" do
      rubygem = Factory(:rubygem)
      ownership = rubygem.ownerships.create(:user => @user)

      post :create, :rubygem_id => rubygem.id
      assert_response :success
      assert_equal ownership.token, @response.body
    end
  end
end

