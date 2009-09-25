require 'test_helper'

class MigrationsControllerTest < ActionController::TestCase
  context "with a rubygem" do
    setup do
      @rubygem = Factory(:rubygem)
    end
    should_forbid_access_when("starting the migration") { post :create, :rubygem_id => @rubygem }
    should_forbid_access_when("checking the migration") { put :update, :rubygem_id => @rubygem }
  end

  context "with a confirmed user authenticated" do
    setup do
      @user = Factory(:email_confirmed_user)
      @request.env["Authorization"] = @user.api_key
    end

    should "respond with 404 if no rubygem is found" do
      name = Factory.next(:name)
      assert ! Rubygem.exists?(:name => name)
      post :create, :rubygem_id => name
      assert_response :not_found
    end

    should "respond with a 403 if the gem is already owned" do
      other_user = Factory(:email_confirmed_user)
      create_gem(other_user)
      post :create, :rubygem_id => @rubygem.to_param
      assert_response :forbidden
    end

    context "with a rubygem" do
      setup do
        @rubygem = Factory(:rubygem)
      end

      should "render the ownership token if the migration has not been completed" do
        post :create, :rubygem_id => @rubygem.to_param
        assert_response :success
        assert_equal Ownership.last.token, @response.body
      end

      should "not create another ownership if migration is started again" do
        ownership = @rubygem.ownerships.create(:user => @user)

        post :create, :rubygem_id => @rubygem.to_param
        assert_response :success
        assert_equal ownership.token, @response.body
      end

      context "without an ownership" do
        should "respond with forbidden" do
          put :update, :rubygem_id => @rubygem.to_param
          assert_response :forbidden
          assert_match /create a migration token first/, @response.body
        end
      end

      context "with an ownership" do
        setup do
          @ownership = @rubygem.ownerships.create(:user => @user)
        end

        should "respond with created if the token has been found" do
          stub_uploaded_token(@rubygem.name, @ownership.token)

          put :update, :rubygem_id => @rubygem.to_param
          assert_response :created
          assert_match /has been migrated/, @response.body
        end

        should "respond with accepted if the token hasn't been found" do
          stub_uploaded_token(@rubygem.name, "", [404, "Not Found"])

          put :update, :rubygem_id => @rubygem.to_param
          assert_response :accepted
          assert_match /still looking/, @response.body
        end
      end
    end
  end
end

