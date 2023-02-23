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

  context ".call" do
    setup do
      @client_response_token = "10000000-aaaa-bbbb-cccc-000000000001"
    end

    context "when hcaptcha verifies the captcha response" do
      should "return true" do
        RestClient.expects(:post)
          .with(anything,
            has_entries(response: @client_response_token, remoteip: @ip),
            has_entries("Content-Type" => "application/x-www-form-urlencoded"))
          .returns({ success: true }.to_json)

        assert HcaptchaVerifier.call(@client_response_token, @ip)
      end
    end

    context "when hcaptcha cannot verify the captcha response due to bot activity" do
      should "return false" do
        RestClient.expects(:post)
          .with(anything,
            has_entries(response: @client_response_token, remoteip: @ip),
            has_entries("Content-Type" => "application/x-www-form-urlencoded"))
          .returns({ success: false }.to_json)
        refute HcaptchaVerifier.call(@client_response_token, @ip)
      end

      should "not log an error" do
        Rails.logger.stubs(:error).raises("Rails.logger.error was called!")
        assert_nothing_raised do
          HcaptchaVerifier.call(@client_response_token, @ip)
        end
      end
    end

    context "when hcaptcha cannot verify the captcha response due to API error" do
      should "return false" do
        RestClient.expects(:post)
          .with(anything,
            has_entries(response: @client_response_token, remoteip: @ip),
            has_entries("Content-Type" => "application/x-www-form-urlencoded"))
          .returns({ success: false, error_codes: ["invalid-or-already-seen-response"] }.to_json)

        refute HcaptchaVerifier.call(@client_response_token, @ip)
      end

      should "log an error" do
        RestClient.expects(:post)
          .with(anything,
            has_entries(response: @client_response_token, remoteip: @ip),
            has_entries("Content-Type" => "application/x-www-form-urlencoded"))
          .returns({ success: false, error_codes: ["invalid-or-already-seen-response"] }.to_json)
        Rails.logger.expects(:error).with("hCaptcha verification failed: invalid-or-already-seen-response")

        HcaptchaVerifier.call(@client_response_token, @ip)
      end
    end
  end
end
