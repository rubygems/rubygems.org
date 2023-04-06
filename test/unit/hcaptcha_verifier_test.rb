require "test_helper"
require "helpers/rate_limit_helpers"

class HcaptchaVerifierTest < ActiveSupport::TestCase
  include RateLimitHelpers

  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear

    @ip = "1.2.3.4"
    @user = create(:user, email: "elmo@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD,
                  remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
  end

  context ".should_verify_sign_in?" do
    context "when the user has not yet tried to login in the past hour" do
      should "returns false" do
        refute HcaptchaVerifier.should_verify_sign_in?(@user.email)
      end
    end

    context "when the user has tried to login a couple times in the past hour" do
      setup do
        scope = Rack::Attack::LOGIN_THROTTLE_PER_USER_KEY
        update_limit_for("#{scope}:#{@user.email}", 2, Rack::Attack::LOGIN_LIMIT_PERIOD)
      end

      should "returns false" do
        refute HcaptchaVerifier.should_verify_sign_in?(@user.email)
      end
    end

    context "when the user has tried to login 4 or more times in the past hour" do
      setup do
        scope = Rack::Attack::LOGIN_THROTTLE_PER_USER_KEY
        update_limit_for("#{scope}:#{@user.email}", 4, Rack::Attack::LOGIN_LIMIT_PERIOD)
      end

      should "returns true" do
        assert HcaptchaVerifier.should_verify_sign_in?(@user.email)
      end
    end
  end

  context ".should_verify_sign_up?" do
    context "when the user has not yet tried to sign up in the past hour" do
      should "returns false" do
        refute HcaptchaVerifier.should_verify_sign_up?(@ip)
      end
    end

    context "when the user has tried to sign up once in the past hour" do
      setup do
        scope = Rack::Attack::SIGN_UP_THROTTLE_PER_IP_KEY
        update_limit_for("#{scope}:#{@ip}", 1, Rack::Attack::SIGN_UP_LIMIT_PERIOD)
      end

      should "returns false" do
        refute HcaptchaVerifier.should_verify_sign_up?(@ip)
      end
    end

    context "when the user has tried to sign up 2 or more times in the past hour" do
      setup do
        scope = Rack::Attack::SIGN_UP_THROTTLE_PER_IP_KEY
        update_limit_for("#{scope}:#{@ip}", 2, Rack::Attack::SIGN_UP_LIMIT_PERIOD)
      end

      should "returns true" do
        assert HcaptchaVerifier.should_verify_sign_up?(@ip)
      end
    end
  end

  context ".call" do
    setup do
      @client_response_token = "10000000-aaaa-bbbb-cccc-000000000001"
    end

    context "when hcaptcha verifies the captcha response" do
      should "return true" do
        connection = mock
        response = mock

        Faraday.expects(:new)
          .with(anything, anything)
          .returns(connection)
        connection.expects(:post).with(anything,
          has_entries(response: @client_response_token, remoteip: @ip))
          .returns(response)
        response.expects(:body).returns({ "success" => true })

        assert HcaptchaVerifier.call(@client_response_token, @ip)
      end
    end

    context "when hcaptcha cannot verify the captcha response due to bot activity" do
      should "return false" do
        connection = mock
        response = mock

        Faraday.expects(:new)
          .with(anything, anything)
          .returns(connection)
        connection.expects(:post).with(anything,
          has_entries(response: @client_response_token, remoteip: @ip))
          .returns(response)
        response.expects(:body).returns({ "success" => false })

        refute HcaptchaVerifier.call(@client_response_token, @ip)
      end

      should "not log an error" do
        connection = mock
        response = mock

        Faraday.expects(:new)
          .with(anything, anything)
          .returns(connection)
        connection.expects(:post).with(anything,
          has_entries(response: @client_response_token, remoteip: @ip))
          .returns(response)
        response.expects(:body).returns({ "success" => false })

        Rails.logger.stubs(:error).raises("Rails.logger.error was called!")

        assert_nothing_raised do
          HcaptchaVerifier.call(@client_response_token, @ip)
        end
      end
    end

    context "when hcaptcha cannot verify the captcha response due to API error" do
      should "return false" do
        connection = mock
        response = mock

        Faraday.expects(:new)
          .with(anything, anything)
          .returns(connection)
        connection.expects(:post).with(anything,
          has_entries(response: @client_response_token, remoteip: @ip))
          .returns(response)
        response.expects(:body).returns({ "success" => false, "error_codes" => ["invalid-or-already-seen-response"] })

        refute HcaptchaVerifier.call(@client_response_token, @ip)
      end

      should "log an error" do
        connection = mock
        response = mock

        Faraday.expects(:new)
          .with(anything, anything)
          .returns(connection)
        connection.expects(:post).with(anything,
          has_entries(response: @client_response_token, remoteip: @ip))
          .returns(response)
        response.expects(:body).returns({ "success" => false, "error_codes" => ["invalid-or-already-seen-response"] })

        Rails.logger.expects(:error).with("hCaptcha verification failed: invalid-or-already-seen-response")

        HcaptchaVerifier.call(@client_response_token, @ip)
      end
    end
  end
end
