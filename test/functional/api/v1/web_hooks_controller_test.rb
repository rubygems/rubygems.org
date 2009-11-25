require 'test_helper'

class Api::V1::WebHooksControllerTest < ActionController::TestCase
  context "When logged in" do
     setup do
       @user = Factory(:email_confirmed_user)
       sign_in_as(@user)
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
   end
end

