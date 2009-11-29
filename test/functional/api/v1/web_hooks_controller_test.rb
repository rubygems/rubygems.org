require 'test_helper'

class Api::V1::WebHooksControllerTest < ActionController::TestCase
  should_forbid_access_when("creating a web hook") { post :create }
  
  context "When logged in" do
     setup do
       @user = Factory(:email_confirmed_user)
       @request.env["HTTP_AUTHORIZATION"] = @user.api_key
     end

     context "On POST to create hook for a gem that's hosted" do

       setup do
         @rubygem = Factory(:rubygem)
         Factory(:version, :rubygem => @rubygem)
         post :create, {:gem_name => @rubygem.name, :url => "http://example.org"}
       end

       should_assign_to(:web_hook)
       should_respond_with 201

      context "on POST to create hook that already exists" do
        
        setup do
          post :create, {:gem_name => @rubygem.name, :url => "http://example.org"}
        end

        should("be only 1 web hook"){ assert_equal 1, WebHook.count }
        should_respond_with 409
      end

     end

     context "On POST to create a hook for a gem that doesn't exist here" do
       setup do
         post :create, {:gem_name => "a gem that doesnt' exist", :url => "http://example.org"}
       end
       
       should_not_assign_to(:web_hook)
       should_respond_with 404
     end
   end
end

