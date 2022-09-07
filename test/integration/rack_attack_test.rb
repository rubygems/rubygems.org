require "test_helper"
require "helpers/rate_limit_helpers"

class RackAttackTest < ActionDispatch::IntegrationTest
  include RateLimitHelpers

  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear

    @ip_address = "1.2.3.4"
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD,
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

    should "allow email confirmation resend" do
      stay_under_limit_for("clearance/ip/1")
      stay_under_email_limit_for("email_confirmations/email")

      post "/email_confirmations",
        params: { email_confirmation: { email: @user.email } },
        headers: { REMOTE_ADDR: @ip_address }
      follow_redirect!
      assert_response :success
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
        create(:api_key, key: "12334", push_rubygem: true, user: @user)
      end

      should "allow gem push by ip" do
        stay_under_push_limit_for("api/push/ip")

        post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem").read,
          headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", CONTENT_TYPE: "application/octet-stream" }

        assert_response :success
      end
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

    context "expontential backoff" do
      context "with successful gem push" do
        setup do
          Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
            under_backoff_limit = (Rack::Attack::EXP_BASE_REQUEST_LIMIT * level) - 1
            @push_exp_throttle_level_key = "#{Rack::Attack::PUSH_EXP_THROTTLE_KEY}/#{level}:#{@ip_address}"
            under_backoff_limit.times { Rack::Attack.cache.count(@push_exp_throttle_level_key, exp_base_limit_period**level) }

            @push_throttle_per_user_key = "#{Rack::Attack::PUSH_THROTTLE_PER_USER_KEY}/#{level}:#{@user.display_id}"
            under_backoff_limit.times { Rack::Attack.cache.count(@push_throttle_per_user_key, exp_base_limit_period**level) }
          end

          create(:api_key, key: "12334", push_rubygem: true, user: @user)
          post "/api/v1/gems",
            params: gem_file("test-0.0.0.gem").read,
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
            params: gem_file("test-1.0.0.gem").read,
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", CONTENT_TYPE: "application/octet-stream" }

          assert_response :ok
        end
      end

      context "ui requests" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
          stay_under_exponential_limit("clearance/ip")
        end

        should "allow for mfa sign in" do
          post "/session", params: { session: { who: @user.handle, password: @user.password } } # sets session[:mfa_user]

          post "/session/mfa_create",
            params: { otp: ROTP::TOTP.new(@user.mfa_seed).now },
            headers: { REMOTE_ADDR: @ip_address }

          assert_redirected_to "/dashboard"
        end

        should "allow mfa forgot password" do
          @user.forgot_password!
          post "/users/#{@user.id}/password/mfa_edit",
            params: { token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.mfa_seed).now },
            headers: { REMOTE_ADDR: @ip_address }

          assert_response :ok
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
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
          stay_under_exponential_limit("api/ip")

          create(:api_key, key: "12334", add_owner: true, yank_rubygem: true, remove_owner: true, user: @user)
          @rubygem = create(:rubygem, name: "test", number: "0.0.1")
          create(:ownership, user: @user, rubygem: @rubygem)
        end

        should "allow gem yank by ip" do
          delete "/api/v1/gems/yank",
            params: { gem_name: @rubygem.to_param, version: @rubygem.latest_version.number },
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", HTTP_OTP: ROTP::TOTP.new(@user.mfa_seed).now }

          assert_response :success
        end

        should "allow owner add by ip" do
          second_user = create(:user)

          post "/api/v1/gems/#{@rubygem.name}/owners",
            params: { rubygem_id: @rubygem.to_param, email: second_user.email },
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", HTTP_OTP: ROTP::TOTP.new(@user.mfa_seed).now }

          assert_response :success
        end

        should "allow owner remove by ip" do
          second_user = create(:user)
          create(:ownership, user: second_user, rubygem: @rubygem)

          delete "/api/v1/gems/#{@rubygem.name}/owners",
            params: { rubygem_id: @rubygem.to_param, email: second_user.email },
            headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", HTTP_OTP: ROTP::TOTP.new(@user.mfa_seed).now }

          assert_response :success
        end
      end
    end

    context "ownership requests" do
      setup do
        sign_in_as(@user)
        @rubygem = create(:rubygem, name: "test", downloads: 2_000)
        create(:version, rubygem: @rubygem, created_at: 2.years.ago)
        stay_under_ownership_request_limit_for("ownership_requests/email")
        post "/gems/#{@rubygem.name}/ownership_requests", params: { rubygem_id: @rubygem.name, note: "small note" }
      end

      should "allow creating new requests" do
        assert_redirected_to "/gems/test/adoptions"
        assert_equal "small note", @rubygem.ownership_requests.last.note
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

    context "api requests" do
      setup do
        @rubygem = create(:rubygem, name: "test", number: "0.0.1")
        @rubygem.ownerships.create(user: @user)
      end

      should "throttle gem push by ip" do
        exceed_push_limit_for("api/push/ip")
        create(:api_key, key: "12334", push_rubygem: true, user: @user)

        post "/api/v1/gems",
          params: gem_file("test-1.0.0.gem").read,
          headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: "12334", CONTENT_TYPE: "application/octet-stream" }

        assert_response :too_many_requests
      end
    end

    context "exponential backoff" do
      setup do
        @mfa_max_period = { 1 => 300, 2 => 90_000 }
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
        @api_key = "12345"
        create(:api_key, key: @api_key, user: @user)
      end

      Rack::Attack::EXP_BACKOFF_LEVELS.each do |level|
        should "throttle for mfa sign in at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("clearance/ip/#{level}", level)
            post "/session/mfa_create", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle for mfa sign in per user at level #{level}" do
          freeze_time do
            # sign page sets mfa_user in session
            post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
            exceed_exponential_user_limit_for("clearance/user/#{level}", @user.id, level)
            post "/session/mfa_create"

            assert_throttle_at(level)
          end
        end

        should "throttle gem push at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("#{Rack::Attack::PUSH_EXP_THROTTLE_KEY}/#{level}", level)

            post "/api/v1/gems",
              params: gem_file("test-0.0.0.gem").read,
              headers: { REMOTE_ADDR: @ip_address, HTTP_AUTHORIZATION: @user.api_key, CONTENT_TYPE: "application/octet-stream" }

            assert_throttle_at(level)
          end
        end

        should "throttle mfa create at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("clearance/ip/#{level}", level)
            post "/multifactor_auth", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle mfa create per user at level #{level}" do
          freeze_time do
            sign_in_as(@user)
            exceed_exponential_user_limit_for("clearance/user/#{level}", @user.email, level)
            post "/multifactor_auth"

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
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.display_id, level)
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
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.display_id, level)
            post "/api/v1/api_key.json", headers: { HTTP_AUTHORIZATION: @api_key }

            assert_throttle_at(level)
          end
        end

        should "throttle mfa forgot password at level #{level}" do
          freeze_time do
            exceed_exponential_limit_for("clearance/ip/#{level}", level)
            post "/users/#{@user.id}/password/mfa_edit", headers: { REMOTE_ADDR: @ip_address }

            assert_throttle_at(level)
          end
        end

        should "throttle for mfa forgot password per user at level #{level}" do
          freeze_time do
            @user.forgot_password!
            exceed_exponential_user_limit_for("clearance/user/#{level}", @user.confirmation_token, level)

            post "/users/#{@user.id}/password/mfa_edit",
              params: { token: @user.confirmation_token, otp: ROTP::TOTP.new(@user.mfa_seed).now }

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
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.display_id, level)
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
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.display_id, level)
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
            exceed_exponential_api_key_limit_for("api/key/#{level}", @user.display_id, level)
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
          post "/passwords",
               params: { password: { email: "Nick@example.com" } }

          assert_response :too_many_requests
        end

        should "throttle for sign in ignoring spaces" do
          post "/passwords",
               params: { password: { email: "n ick@example.com" } }

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

    context "ownership requests" do
      setup do
        sign_in_as(@user)
        @rubygem = create(:rubygem, name: "test", downloads: 2_000)
        create(:version, rubygem: @rubygem, created_at: 2.years.ago)
        exceed_ownership_request_limit_for("ownership_requests/email")
        post "/gems/#{@rubygem.name}/ownership_requests", params: { rubygem_id: @rubygem.name, note: "small note" }
      end

      should "throttle creating new requests" do
        assert_response :too_many_requests
        assert_empty @rubygem.ownership_requests
      end
    end
  end

  private

  def sign_in_as(user)
    post session_path(session: { who: user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
    post "/session/mfa_create", params: { otp: ROTP::TOTP.new(@user.mfa_seed).now } if user.mfa_enabled?
  end

  def set_owners_session(_rubygem, user)
    sign_in_as(user)
    post authenticate_session_path(verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end
end
