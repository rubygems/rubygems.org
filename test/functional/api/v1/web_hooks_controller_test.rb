require 'test_helper'

class Api::V1::WebHooksControllerTest < ActionController::TestCase
  should_forbid_access_when("creating a web hook") { post :create }
  
  context "When logged in" do
    setup do
      @url = "http://example.org"
      @user = Factory(:email_confirmed_user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "with a rubygem" do
      setup do
        @rubygem = Factory(:rubygem)
        Factory(:version, :rubygem => @rubygem)
      end

      context "On POST to create hook for a gem that's hosted" do
        setup do
          post :create, :gem_name => @rubygem.name, :url => @url
        end

        should_respond_with :created
        should "say webhook was created" do
          assert_contain "Successfully created webhook for #{@rubygem.name} to #{@url}"
        end
        should "link webhook to current user and rubygem" do
          assert_equal @user, WebHook.last.user
          assert_equal @rubygem, WebHook.last.rubygem
        end
      end

      context "on POST to create hook that already exists" do
        setup do
          Factory(:web_hook, :rubygem => @rubygem, :url => @url, :user => @user)
          post :create, :gem_name => @rubygem.name, :url => @url
        end

        should_respond_with :conflict
        should "be only 1 web hook" do
          assert_equal 1, WebHook.count
          assert_contain "#{@url} has already been registered for #{@rubygem.name}"
        end
      end

      context "On POST to create hook for all gems" do
        setup do
          post :create, :gem_name => '*', :url => @url
        end

        should_respond_with :created
        should "link webhook to current user and no rubygem" do
          assert_equal @user, WebHook.last.user
          assert_nil WebHook.last.rubygem
        end
      end
    end

    context "On POST to create a hook for a gem that doesn't exist here" do
      setup do
        post :create, :gem_name => "a gem that doesn't exist", :url => @url
      end
      
      should_respond_with :not_found
      should "say gem is not found" do
        assert_contain "could not be found"
      end
    end
      
    context "on POST to global web hook that already exists" do
      setup do
        Factory(:web_hook, :url => @url, :user => @user)
        post :create, :gem_name => '*', :url => @url
      end

      should_respond_with :conflict
      should "be only 1 web hook" do
         assert_equal 1, WebHook.count
      end
    end
  end
end

