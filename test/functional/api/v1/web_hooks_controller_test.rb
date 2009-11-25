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
         post :create, :web_hook => {:gem_name => @rubygem.name, :url => "http://example.org"}
       end

       should_assign_to(:web_hook)
       should_respond_with 201
     end
     
     context "On POST to create a hook for a gem that doesn't exist here" do
       setup do
         post :create, :web_hook => {:gem_name => "a gem that doesnt' exist", :url => "http://example.org"}
       end
       
       should_not_assign_to(:web_hook)
       should_respond_with 404
     end
   end
end

