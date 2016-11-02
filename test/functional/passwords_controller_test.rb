require 'test_helper'

class PasswordsControllerTest < ActionController::TestCase
  context "on POST to create" do
    context "when missing a parameter" do
      should "raises parameter missing" do
        post :create
        assert_response :bad_request
        assert page.has_content?("Request is missing param 'password'")
      end
    end
  end
end
