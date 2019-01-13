require "test_helper"
require "helpers/rate_limit_helpers"

class RackAttackTest < ActionDispatch::IntegrationTest
  include RateLimitHelper

  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear

    @ip_address = "1.2.3.4"
    @user = create(:user, email: "nick@example.com", password: "secret12345")
  end

  context "requests is lower than limit" do
    should "allow sign in" do
      stay_under_limit_for("clearance/ip")

      post "/session",
        params: { session: { who: @user.email, password: @user.password } },
        headers: { REMOTE_ADDR: @ip_address }
      follow_redirect!

      assert_response :success
    end

    should "allow sign up" do
      stay_under_limit_for("clearance/ip")

      user = build(:user)
      post "/users",
        params: { user: { email: user.email, password: user.password } },
        headers: { REMOTE_ADDR: @ip_address }
      follow_redirect!

      assert_response :success
    end

    should "allow forgot password" do
      stay_under_limit_for("clearance/ip")
      stay_under_email_limit_for("password/email")

      post "/passwords",
        params: { password: { email: @user.email } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :success
    end

    should "allow api_key show" do
      stay_under_limit_for("api_key/ip")

      get "/api/v1/api_key.json",
        env: { "HTTP_AUTHORIZATION" => encode(@user.handle, @user.password) },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :success
    end

    should "allow email confirmation resend" do
      stay_under_limit_for("clearance/ip")
      stay_under_email_limit_for("email_confirmations/email")

      post "/email_confirmations",
        params: { email_confirmation: { email: @user.email } },
        headers: { REMOTE_ADDR: @ip_address }
      follow_redirect!
      assert_response :success
    end

    context "params" do
      should "return 400 for bad request" do
        post "/session"

        assert_response :bad_request
      end

      should "return 401 for unauthorized request" do
        post "/session", params: { session: { password: @user.password } }

        assert_response :unauthorized
      end
    end
  end

  context "requests is higher than limit" do
    should "throttle sign in" do
      exceed_limit_for("clearance/ip")

      post "/session",
        params: { session: { who: @user.email, password: @user.password } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle sign up" do
      exceed_limit_for("clearance/ip")

      user = build(:user)
      post "/users",
        params: { user: { email: user.email, password: user.password } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle forgot password" do
      exceed_limit_for("clearance/ip")

      post "/passwords",
        params: { password: { email: @user.email } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle api_key show" do
      exceed_limit_for("api_key/ip")

      get "/api/v1/api_key.json",
        env: { "HTTP_AUTHORIZATION" => encode(@user.handle, @user.password) },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle profile update" do
      cookies[:remember_token] = @user.remember_token

      exceed_limit_for("clearance/remember_token")
      patch "/profile",
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle profile delete" do
      cookies[:remember_token] = @user.remember_token

      exceed_limit_for("clearance/remember_token")
      delete "/profile",
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    context "email confirmation" do
      should "throttle by ip" do
        exceed_limit_for("clearance/ip")

        post "/email_confirmations",
          params: { email_confirmation: { email: @user.email } },
          headers: { REMOTE_ADDR: @ip_address }
        assert_response :too_many_requests
      end

      should "throttle by email" do
        exceed_email_limit_for("email_confirmations/email")

        post "/email_confirmations", params: { email_confirmation: { email: @user.email } }
        assert_response :too_many_requests
      end
    end

    context "password update" do
      should "throttle by ip" do
        exceed_limit_for("clearance/ip")

        post "/passwords",
          params: { password: { email: @user.email } },
          headers: { REMOTE_ADDR: @ip_address }

        assert_response :too_many_requests
      end

      should "throttle by email" do
        exceed_email_limit_for("password/email")

        post "/passwords", params: { password: { email: @user.email } }
        assert_response :too_many_requests
      end
    end

    context "gem push" do
      should "throttle by ip" do
        exceed_ip_push_limit

        post "/api/v1/gems",
          headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: @user.api_key },
          env: { 'RAW_POST_DATA' => gem_file("test-1.0.0.gem").read }
        assert_response :too_many_requests
      end

      should "throttle by api key" do
        exceed_key_push_limit

        post "/api/v1/gems",
          headers: { HTTP_AUTHORIZATION: @user.api_key },
          env: { 'RAW_POST_DATA' => gem_file("test-1.0.0.gem").read }
        assert_response :too_many_requests
      end
    end
  end
end
