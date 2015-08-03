class ActiveSupport::TestCase
  def self.should_forbid_access_when(action, &block)
    context "On #{action} with no user credentials" do
      setup do
        instance_eval(&block)
      end
      should "deny access" do
        assert_response 401
        assert_match "Access Denied. Please sign up for an account at https://rubygems.org",
          @response.body
      end
    end

    context "On #{action} with unconfirmed user" do
      setup do
        @user = create(:user)
        @request.env["HTTP_AUTHORIZATION"] = @user.api_key
        instance_eval(&block)
      end
      should "deny access" do
        assert_response 403
        assert_match "Access Denied. Please confirm your RubyGems.org account.", @response.body
      end
    end
  end
end
