# frozen_string_literal: true

require "test_helper"
require "helpers/rate_limit_helpers"

class RackAttackTest < ActionDispatch::IntegrationTest
  include RateLimitHelpers
  include ActionMailer::TestHelper

  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    @ip_address = "1.2.3.4"
    @user = create(:user, email: "nick@rubygems-test.org", password: PasswordHelpers::SECURE_TEST_PASSWORD,
                   remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
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
      update_limit_for("signups/global:global", Rack::Attack::SIGNUP_LIMIT - 1, Rack::Attack::SIGNUP_LIMIT_PERIOD)

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

      post "/password",
        params: { password: { email: @user.email } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :success
    end

    should "allow email confirmation resend" do
      stay_under_limit_for("clearance/ip/1")
      stay_under_email_limit_for("email_confirmations/email")

      post "/email_confirmations",
        params: { email_confirmation: { email: @user.email } },
        headers: { REMOTE_ADDR: @ip_address }
      follow_redirect!

      assert_response :success
    end

    should "allow email confirmation resend via unconfirmed" do
      stay_under_limit_for("clearance/ip/1")
      stay_under_email_limit_for("email_confirmations/email")

      patch "/email_confirmations/unconfirmed",
        headers: { REMOTE_ADDR: @ip_address }
      follow_redirect!

      assert_response :success
    end

    should "allow profile email change under the email confirmation limit" do
      sign_in_as @user
      stay_under_email_limit_for("email_confirmations/email")

      assert_enqueued_email_with Mailer, :email_reset, args: [@user, "new@rubygems-test.org"] do
        patch "/profile",
          params: { user: { unconfirmed_email: "new@rubygems-test.org", password: PasswordHelpers::SECURE_TEST_PASSWORD } },
          headers: { REMOTE_ADDR: @ip_address }
      end
      follow_redirect!

      assert_response :success
      assert_equal "new@rubygems-test.org", @user.reload.unconfirmed_email
    end

    context "owners requests" do
      setup do
        post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
        @rubygem = create(:rubygem)
        create(:ownership, :unconfirmed, rubygem: @rubygem, user: @user)
      end

      teardown do
        delete sign_out_path
      end

      should "allow resending ownership confirmation" do
        stay_under_limit_for("owners/ip")
        stay_under_email_limit_for("owners/email")

        get "/gems/#{@rubygem.name}/owners/resend_confirmation",
            headers: { REMOTE_ADDR: @ip_address }
        follow_redirect!

        assert_response :success
      end
    end

    context "api requests" do
      setup do
        @rubygem = create(:rubygem, name: "test", number: "0.0.1")
        create(:ownership, user: @user, rubygem: @rubygem)
        create(:api_key, key: "12334", scopes: %i[push_rubygem], owner: @user)
      end

      should "allow gem push by ip" do
        stay_under_push_limit_for("api/push/ip")

        post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem", &:read),
          headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", CONTENT_TYPE: "application/octet-stream" }

        assert_response :success
      end
    end

    context "web hook fire requests" do
      setup do
        create(:rubygem, name: "gemcutter", number: "0.0.1")
        create(:api_key, key: "12334", scopes: %i[access_webhooks], owner: @user)

        stub_request(:post, "https://api.hookrelay.dev/hooks///webhook_id-fire")
          .to_return(status: 200, body: '{"id":"delivery-id"}', headers: { "Content-Type" => "application/json" })
        stub_request(:get, "https://app.hookrelay.dev/api/v1/accounts//hooks//deliveries/delivery-id")
          .to_return(status: 200, body: { "status" => "success", "responses" => [
            "code" => 200, "body" => "OK", "headers" => { "Content-Type" => "text/plain" }
          ] }.to_json, headers: { "Content-Type" => "application/json" })
      end

      should "allow web hook fire by ip" do
        post "/api/v1/web_hooks/fire",
          params: { gem_name: WebHook::GLOBAL_PATTERN, url: "http://example.org" },
          headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334" }

        assert_response :success
      end
    end

    context "params" do
      should "return 400 for bad request" do
        post "/session"

        assert_response :bad_request
      end

      should "return 401 for unauthorized request" do
        post "/session", params: { session: { who: "no@rubygems-test.org", password: @user.password } }

        assert_response :unauthorized
      end
    end

    context "expontential backoff" do
      context "with successful gem push" do
        setup do
          Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
            under_backoff_limit = (Rack::Attack::EXP_BASE_REQUEST_LIMIT * level) - 1
            @push_exp_throttle_level_key = "#{Rack::Attack::PUSH_EXP_THROTTLE_KEY}/#{level}:#{@ip_address}"
            under_backoff_limit.times { Rack::Attack.cache.count(@push_exp_throttle_level_key, exp_base_limit_period**level) }

            @push_throttle_per_user_key = "#{Rack::Attack::PUSH_THROTTLE_PER_USER_KEY}/#{level}:#{@user.to_gid}"
            under_backoff_limit.times { Rack::Attack.cache.count(@push_throttle_per_user_key, exp_base_limit_period**level) }
          end

          create(:api_key, key: "12334", scopes: %i[push_rubygem], owner: @user)
          post "/api/v1/gems",
            params: gem_file("test-0.0.0.gem", &:read),
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", CONTENT_TYPE: "application/octet-stream" }
        end

        should "reset gem push rate limit rack attack key" do
          Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
            period = exp_base_limit_period**level

            time_counter = (Time.now.to_i / period).to_i
            prev_time_counter = time_counter - 1

            assert_nil Rack::Attack.cache.read("#{time_counter}:#{@push_exp_throttle_level_key}")
            assert_nil Rack::Attack.cache.read("#{prev_time_counter}:#{@push_exp_throttle_level_key}")
            assert_nil Rack::Attack.cache.read("#{time_counter}:#{@push_throttle_per_user_key}")
            assert_nil Rack::Attack.cache.read("#{prev_time_counter}:#{@push_throttle_per_user_key}")
          end
        end

        should "not rate limit successive requests" do
          post "/api/v1/gems",
            params: gem_file("test-1.0.0.gem", &:read),
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", CONTENT_TYPE: "application/octet-stream" }

          assert_response :ok
        end
      end

      context "ui requests" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
          stay_under_exponential_limit("clearance/ip")
        end

        should "allow for mfa sign in" do
          post "/session", params: { session: { who: @user.handle, password: @user.password } } # sets session[:mfa_user]

          post "/session/otp_create",
            params: { otp: ROTP::TOTP.new(@user.totp_seed).now },
            headers: { REMOTE_ADDR: @ip_address }

          assert_redirected_to "/dashboard"
        end

        should "allow mfa forgot password" do
          token = @user.issue_password_reset!
          get "/password/edit",
            params: { token:, user_id: @user.id }

          assert_response :success
          post "/password/otp_edit",
            params: { otp: ROTP::TOTP.new(@user.totp_seed).now },
            headers: { REMOTE_ADDR: @ip_address }

          assert_redirected_to "/password/reset"
        end

        should "allow reverse_dependencies index" do
          rubygem = create(:rubygem, name: "test", number: "0.0.1")
          get "/gems/#{rubygem.name}/reverse_dependencies",
            headers: { REMOTE_ADDR: @ip_address }

          assert_response :ok
        end
      end

      context "api requests" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          stay_under_exponential_limit("api/ip")

          create(:api_key, key: "12334", scopes: %i[add_owner yank_rubygem remove_owner], owner: @user)
          @rubygem = create(:rubygem, name: "test", number: "0.0.1")
          create(:ownership, user: @user, rubygem: @rubygem)
        end

        should "allow gem yank by ip" do
          delete "/api/v1/gems/yank",
            params: { gem_name: @rubygem.slug, version: @rubygem.latest_version.number },
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", HTTP_OTP: ROTP::TOTP.new(@user.totp_seed).now }

          assert_response :success
        end

        should "allow owner add by ip" do
          second_user = create(:user)

          post "/api/v1/gems/#{@rubygem.name}/owners",
            params: { rubygem_id: @rubygem.slug, email: second_user.email },
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", HTTP_OTP: ROTP::TOTP.new(@user.totp_seed).now }

          assert_response :success
        end

        should "allow owner remove by ip" do
          second_user = create(:user)
          create(:ownership, user: second_user, rubygem: @rubygem)

          delete "/api/v1/gems/#{@rubygem.name}/owners",
            params: { rubygem_id: @rubygem.slug, email: second_user.email },
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", HTTP_OTP: ROTP::TOTP.new(@user.totp_seed).now }

          assert_response :success
        end
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
      update_limit_for("signups/global:global", Rack::Attack::SIGNUP_LIMIT, Rack::Attack::SIGNUP_LIMIT_PERIOD)

      user = build(:user)
      post "/users",
        params: { user: { email: user.email, password: user.password } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle forgot password" do
      exceed_limit_for("clearance/ip")

      post "/password",
        params: { password: { email: @user.email } },
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle verify password" do
      exceed_limit_for("clearance/ip")

      post "/session/authenticate",
           params: { verify_password: { password: "password" } },
           headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle profile update" do
      post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

      exceed_limit_for("clearance/ip")
      patch "/profile",
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle profile update per user" do
      sign_in_as @user
      update_limit_for("password/user:#{@user.email}", exceeding_limit)
      patch "/profile"

      assert_response :too_many_requests
    end

    should "throttle profile delete" do
      post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

      exceed_limit_for("clearance/ip")
      delete "/profile",
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    should "throttle profile delete per user" do
      sign_in_as @user
      update_limit_for("password/user:#{@user.email}", exceeding_limit)
      delete "/profile"

      assert_response :too_many_requests
    end

    should "throttle reverse_dependencies index" do
      exceed_limit_for("clearance/ip")
      rubygem = create(:rubygem, name: "test", number: "0.0.1")
      get "/gems/#{rubygem.name}/reverse_dependencies",
        headers: { REMOTE_ADDR: @ip_address }

      assert_response :too_many_requests
    end

    context "owners requests" do
      setup do
        post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
        @rubygem = create(:rubygem)
        create(:ownership, :unconfirmed, rubygem: @rubygem, user: @user)
      end

      teardown do
        delete sign_out_path
      end

      should "throttle ownership confirmation resend" do
        exceed_limit_for("owners/ip")
        get "/gems/#{@rubygem.name}/owners/resend_confirmation", headers: { REMOTE_ADDR: @ip_address }

        assert_response :too_many_requests
      end

      should "throttle adding owner" do
        exceed_limit_for("owners/ip")
        new_user = create(:user)
        post "/gems/#{@rubygem.name}/owners", params: { owner: new_user.name },
             headers: { REMOTE_ADDR: @ip_address }

        assert_response :too_many_requests
      end

      should "throttle removing owner" do
        exceed_limit_for("owners/ip")
        delete "/gems/#{@rubygem.name}/owners/#{@user.id}", headers: { REMOTE_ADDR: @ip_address }

        assert_response :too_many_requests
      end
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

      should "throttle profile email change by email" do
        sign_in_as @user
        exceed_email_limit_for("email_confirmations/email")

        assert_no_enqueued_emails do
          # the profile form submits as POST with _method=patch, which is what https://hackerone.com/reports/3277048 used
          post "/profile",
            params: { _method: "patch", user: { unconfirmed_email: "new@rubygems-test.org", password: PasswordHelpers::SECURE_TEST_PASSWORD } }
        end

        assert_response :too_many_requests
        assert_nil @user.reload.unconfirmed_email
      end

      should "not throttle profile update that resubmits the current email by email" do
        sign_in_as @user
        exceed_email_limit_for("email_confirmations/email")

        assert_no_enqueued_emails do
          patch "/profile",
            params: { user: { handle: "newhandle", unconfirmed_email: @user.email, password: PasswordHelpers::SECURE_TEST_PASSWORD } }
        end

        assert_redirected_to edit_profile_path
        assert_equal "newhandle", @user.reload.handle
      end
    end

    context "password update" do
      should "throttle by ip" do
        exceed_limit_for("clearance/ip")

        post "/password",
          params: { password: { email: @user.email } },
          headers: { REMOTE_ADDR: @ip_address }

        assert_response :too_many_requests
      end

      should "throttle by email" do
        exceed_email_limit_for("password/email")

        post "/password", params: { password: { email: @user.email } }

        assert_response :too_many_requests
      end
    end

    context "api requests" do
      setup do
        @rubygem = create(:rubygem, name: "test", number: "0.0.1")
        @rubygem.ownerships.create(user: @user)
      end

      should "throttle gem push by ip" do
        exceed_push_limit_for("api/push/ip")
        create(:api_key, key: "12334", scopes: %i[push_rubygem], owner: @user)

        post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem", &:read),
          headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", CONTENT_TYPE: "application/octet-stream" }

        assert_response :too_many_requests
      end

      should "throttle web hook fire by ip" do
        update_limit_for("webhook_fire/ip:#{@ip_address}", Rack::Attack::WEBHOOK_FIRE_LIMIT)

        post "/api/v1/web_hooks/fire", headers: { REMOTE_ADDR: @ip_address }

        assert_response :too_many_requests
      end

      should "throttle web hook fire by api key" do
        api_key = create(:api_key, key: "12334", scopes: %i[access_webhooks], owner: @user)
        update_limit_for("webhook_fire/api_key:#{api_key.owner.to_gid}", Rack::Attack::WEBHOOK_FIRE_LIMIT)

        post "/api/v1/web_hooks/fire", headers: { HTTP_AUTHORIZATION: "12334" }

        assert_response :too_many_requests
      end
    end

    context "exponential backoff" do
      setup do
        @mfa_max_period = { 1 => 300, 2 => 90_000 }
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        @api_key = "12345"
        create(:api_key, key: @api_key, owner: @user)
      end

      email_confirmation_limiters = %i[ip user]
      {
        "confirm without MFA" => :none,
        "otp_update with TOTP" => :totp,
        "otp_update with a recovery code" => :recovery_code,
        "webauthn_update with WebAuthn" => :webauthn
      }.each do |name, factor|
        should "allow email confirmation #{name} just under the limits" do
          freeze_time do
            path, params = prepare_email_confirmation_submission(factor)
            Rack::Attack.cache.store.clear
            Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
              limit = (Rack::Attack::EXP_BASE_REQUEST_LIMIT * level) - 1
              update_limit_for("clearance/ip/#{level}:#{@ip_address}", limit, exp_base_limit_period**level)
              update_limit_for("clearance/user/#{level}:#{@user.id}", limit, exp_base_limit_period**level)
            end

            post path, params:, headers: { REMOTE_ADDR: @ip_address }

            assert_redirected_to "/sign_in"
            assert_equal "new@rubygems-test.org", @user.reload.email
          end
        end

        Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
          email_confirmation_limiters.each do |limiter|
            should "throttle email confirmation #{name} by #{limiter} at level #{level}" do
              freeze_time do
                path, params = prepare_email_confirmation_submission(factor)
                user_state = @user.reload.attributes
                credential_state = @webauthn_credential&.reload&.attributes
                if limiter == :ip
                  exceed_exponential_limit_for("clearance/ip/#{level}", level)
                else
                  exceed_exponential_user_limit_for("clearance/user/#{level}", @user.id, level)
                end

                post path, params:, headers: { REMOTE_ADDR: @ip_address }

                assert_throttle_at(level)
                assert_equal user_state, @user.reload.attributes
                assert_equal credential_state, @webauthn_credential.reload.attributes if @webauthn_credential

                assert @user.valid_email_confirmation_token?(@email_confirmation_token)
              end
            end
          end
        end
      end

      Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
        should "throttle for mfa sign in at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("clearance/ip/#{level}", level)
            post "/session/otp_create", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle for mfa sign in per user at level #{level}" do
          freeze_time do
            # sign page sets mfa_user in session
            post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
            exceed_exponential_user_limit_for("clearance/user/#{level}", @user.id, level)
            post "/session/otp_create"

            assert_throttle_at(level)
          end
        end

        should "throttle gem push at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("#{Rack::Attack::PUSH_EXP_THROTTLE_KEY}/#{level}", level)

            post "/api/v1/gems",
              params: gem_file("test-0.0.0.gem", &:read),
              headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: @user.api_key, CONTENT_TYPE: "application/octet-stream" }

            assert_throttle_at(level)
          end
        end

        should "throttle totp create at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("clearance/ip/#{level}", level)
            post "/totp", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle totp create per user at level #{level}" do
          freeze_time do
            sign_in_as(@user)
            exceed_exponential_user_limit_for("clearance/user/#{level}", @user.email, level)
            post "/totp"

            assert_throttle_at(level)
          end
        end

        should "throttle totp destroy at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("clearance/ip/#{level}", level)
            post "/totp", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle totp destroy per user at level #{level}" do
          freeze_time do
            sign_in_as(@user)
            exceed_exponential_user_limit_for("clearance/user/#{level}", @user.email, level)
            post "/totp"

            assert_throttle_at(level)
          end
        end

        should "throttle mfa update at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("clearance/ip/#{level}", level)
            put "/multifactor_auth", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle mfa update per user at level #{level}" do
          freeze_time do
            sign_in_as(@user)
            exceed_exponential_user_limit_for("clearance/user/#{level}", @user.email, level)
            put "/multifactor_auth"

            assert_throttle_at(level)
          end
        end

        should "throttle api key show at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("api/ip/#{level}", level)
            get "/api/v1/api_key.json", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle api key show by api key #{level}" do
          freeze_time do
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.to_gid, level)
            get "/api/v1/api_key.json", headers: { HTTP_AUTHORIZATION: @api_key }

            assert_throttle_at(level)
          end
        end

        should "throttle api key create at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("api/ip/#{level}", level)
            get "/api/v1/api_key.json", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle api key create by api key #{level}" do
          freeze_time do
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.to_gid, level)
            post "/api/v1/api_key.json", headers: { HTTP_AUTHORIZATION: @api_key }

            assert_throttle_at(level)
          end
        end

        should "throttle mfa forgot password at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("clearance/ip/#{level}", level)
            post "/password/otp_edit", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle for mfa forgot password per user at level #{level}" do
          freeze_time do
            token = @user.issue_password_reset!
            get "/password/edit", params: { token:, user_id: @user.id }
            exceed_exponential_user_limit_for("clearance/user/#{level}", @user.id, level)

            post "/password/otp_edit",
              params: { otp: ROTP::TOTP.new(@user.totp_seed).now }

            assert_throttle_at(level)
          end
        end

        should "throttle gem yank by ip #{level}" do
          freeze_time do
            exceed_exponential_limit_for("api/ip/#{level}", level)
            delete "/api/v1/gems/yank", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle gem yank by api key #{level}" do
          freeze_time do
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.to_gid, level)
            delete "/api/v1/gems/yank", headers: { HTTP_AUTHORIZATION: @api_key }

            assert_throttle_at(level)
          end
        end

        should "throttle owner add by ip #{level}" do
          freeze_time do
            exceed_exponential_limit_for("api/ip/#{level}", level)
            post "/api/v1/gems/somegem/owners", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle owner add by api key #{level}" do
          freeze_time do
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.to_gid, level)
            post "/api/v1/gems/somegem/owners", headers: { HTTP_AUTHORIZATION: @api_key }

            assert_throttle_at(level)
          end
        end

        should "throttle owner remove by ip #{level}" do
          freeze_time do
            exceed_exponential_limit_for("api/ip/#{level}", level)
            delete "/api/v1/gems/somegem/owners", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle owner remove by api key #{level}" do
          freeze_time do
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.to_gid, level)
            delete "/api/v1/gems/somegem/owners", headers: { HTTP_AUTHORIZATION: @api_key }

            assert_throttle_at(level)
          end
        end
      end
    end

    context "with per email limits" do
      context "for sign in" do
        setup { update_limit_for("password/email:#{@user.email}", exceeding_limit) }

        should "throttle for sign in ignoring case" do
          post "/password",
               params: { password: { email: "Nick@rubygems-test.org" } }

          assert_response :too_many_requests
        end

        should "throttle for sign in ignoring spaces" do
          post "/password",
               params: { password: { email: "n ick@rubygems-test.org" } }

          assert_response :too_many_requests
        end
      end

      context "for ownerships" do
        setup do
          @rubygem = create(:rubygem)
          create(:ownership, rubygem: @rubygem, user: @user)
        end

        teardown do
          delete sign_out_path
        end

        should "throttle resending ownership confirmation" do
          other_user = create(:user)
          set_owners_session(@rubygem, other_user)
          create(:ownership, :unconfirmed, rubygem: @rubygem, user: other_user)
          update_limit_for("owners/email:#{other_user.email}", exceeding_email_limit)
          get "/gems/#{@rubygem.name}/owners/resend_confirmation"

          assert_response :too_many_requests
        end

        should "throttle adding owner" do
          set_owners_session(@rubygem, @user)
          new_user = create(:user)
          exceed_email_limit_for("owners/email")
          post "/gems/#{@rubygem.name}/owners", params: { handle: new_user.display_id }

          assert_response :too_many_requests
        end

        should "throttle removing owner" do
          set_owners_session(@rubygem, @user)
          exceed_email_limit_for("owners/email")
          delete "/gems/#{@rubygem.name}/owners/#{@user.display_id}"

          assert_response :too_many_requests
        end
      end
    end
  end

  private

  def sign_in_as(user)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
    post "/session/otp_create", params: { otp: ROTP::TOTP.new(@user.totp_seed).now } if user.mfa_enabled?
  end

  def begin_email_change_confirmation
    @user.update!(unconfirmed_email: "new@rubygems-test.org")
    @email_confirmation_token = @user.issue_email_confirmation!(@user.unconfirmed_email)
    get "/email_confirmations/confirm", params: { token: @email_confirmation_token }
  end

  # Builds an email confirmation request that would succeed if not throttled.
  # MFA challenges are started first, since starting one also counts against the limits.
  def prepare_email_confirmation_submission(factor)
    recovery_code = @user.new_mfa_recovery_codes&.first
    @user.disable_totp! if factor == :none
    @webauthn_credential = create(:webauthn_credential, user: @user) if factor == :webauthn
    begin_email_change_confirmation
    confirmation = session[:email_confirmation_id]
    return ["/email_confirmations/confirm", confirmation:] if factor == :none

    post "/email_confirmations/confirm", params: { confirmation: }

    assert_response :success
    case factor
    when :totp
      ["/email_confirmations/otp_update", confirmation:, otp: ROTP::TOTP.new(@user.totp_seed).now]
    when :recovery_code
      ["/email_confirmations/otp_update", confirmation:, otp: recovery_code]
    when :webauthn
      client = WebAuthn::FakeClient.new(WebAuthn.configuration.allowed_origins.first, encoding: false)
      WebauthnHelpers.create_credential(webauthn_credential: @webauthn_credential, client:)
      credentials = WebauthnHelpers.get_result(client:, challenge: session[:webauthn_authentication]["challenge"])
      ["/email_confirmations/webauthn_update", confirmation:, credentials:]
    end
  end

  def set_owners_session(_rubygem, user)
    sign_in_as(user)
    post authenticate_session_path(verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end
end
