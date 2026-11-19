# frozen_string_literal: true

require "test_helper"

class Api::V1::ApiKeysControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  should "route new paths to new controller" do
    route = { controller: "api/v1/api_keys", action: "show" }

    assert_recognizes(route, "/api/v1/api_key")
  end

  def authorize_with(str)
    @request.env["HTTP_AUTHORIZATION"] = "Basic #{Base64.encode64(str)}"
  end

  def self.should_deny_access
    should "deny access" do
      assert_response :unauthorized
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  def self.should_deny_access_incorrect_otp
    should "deny access" do
      assert_response :unauthorized
      assert_match I18n.t("otp_incorrect"), @response.body
    end
  end

  def self.should_deny_access_missing_otp
    should "deny access" do
      assert_response :unauthorized
      assert_match I18n.t("otp_missing"), @response.body
    end

    should "return body that starts with MFA enabled message" do
      assert @response.body.start_with?("You have enabled multifactor authentication")
    end
  end

  def self.should_return_api_key_successfully
    should respond_with :success
    should "return API key" do
      hashed_key = @user.api_keys.first.hashed_key

      assert_equal hashed_key, Digest::SHA256.hexdigest(@response.body)
    end
  end

  def self.should_expect_otp_for_create
    context "without OTP" do
      setup { post :create }
      should_deny_access_missing_otp
    end

    context "with incorrect OTP" do
      setup do
        @request.env["HTTP_OTP"] = "11111"
        post :create
      end

      should_deny_access_incorrect_otp
    end

    context "with correct OTP" do
      setup do
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
        post :create, params: { name: "test", index_rubygems: "true" }
      end

      should_return_api_key_successfully
    end
  end

  def self.should_expect_otp_for_update
    context "without OTP" do
      setup { put :update }
      should_deny_access_missing_otp
    end

    context "with incorrect OTP" do
      setup do
        @request.env["HTTP_OTP"] = "11111"
        put :update
      end

      should_deny_access_incorrect_otp
    end

    context "with correct OTP" do
      setup do
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
        @api_key = create(:api_key, owner: @user, key: "12345", scopes: %i[push_rubygem])

        put :update, params: { api_key: "12345", index_rubygems: "true" }
        @api_key.reload
      end

      should respond_with :success
      should "keep current scope enabled and update scope in params" do
        assert_predicate @api_key, :can_index_rubygems?
        assert_predicate @api_key, :can_push_rubygem?
      end
    end
  end

  context "on GET to show (retired endpoint)" do
    # GET /api/v1/api_key is retired: 410 Gone, mints nothing, regardless of method or credentials.
    should "respond 410 Gone with no credentials" do
      get :show

      assert_response :gone
      assert_match "retired", @response.body
    end

    should "respond 410 Gone with valid credentials and mint nothing" do
      user = create(:user)
      authorize_with("#{user.email}:#{user.password}")

      assert_no_difference -> { ApiKey.count } do
        get :show
      end

      assert_response :gone
    end

    should "respond 410 Gone to a HEAD request" do
      head :show

      assert_response :gone
    end
  end

  context "on POST to create" do
    setup { @user = create(:user) }

    context "with no credentials" do
      setup { post :create }
      should_deny_access
    end

    context "with bad credentials" do
      setup do
        authorize_with("bad:creds")
        post :create
      end
      should_deny_access
    end

    context "with unconfirmed email" do
      setup do
        @user = create(:user, :unconfirmed)
        authorize_with("#{@user.email}:#{@user.password}")
        post :create, params: { name: "test-key", index_rubygems: "true" }
      end

      should respond_with :forbidden

      should "return email confirmation error" do
        assert_match "Please confirm your email address", @response.body
      end
    end

    context "with correct credentials" do
      setup do
        authorize_with("#{@user.email}:#{@user.password}")
      end

      context "on successful save" do
        setup do
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
          end
        end

        should_return_api_key_successfully

        should "deliver api key created email" do
          refute_empty ActionMailer::Base.deliveries
          email = ActionMailer::Base.deliveries.last

          assert_equal [@user.email], email.to
          assert_equal ["no-reply@mailer.rubygems.org"], email.from
          assert_equal "New API key created for rubygems.org", email.subject
          assert_match "test-key", email.body.to_s
        end
      end

      context "on unsuccessful save" do
        setup do
          post :create, params: { name: "test-key", index_rubygems: "true", show_dashboard: "true" }, format: "text"
        end

        should respond_with :unprocessable_content

        should "not create api key" do
          assert_empty @user.reload.api_keys
        end

        should "respond with error message" do
          assert_equal "Show dashboard scope must be enabled exclusively", @response.body
        end
      end

      context "with MFA param set" do
        setup do
          post :create, params: { name: "mfa", index_rubygems: "true", mfa: "true" }, format: "text"
        end

        should_return_api_key_successfully

        should "have MFA" do
          created_key = @user.api_keys.find_by(name: "mfa")

          assert created_key.mfa
        end
      end

      context "with rubygem_name param set" do
        context "with a valid rubygem" do
          setup do
            @ownership = create(:ownership, user: @user)
          end

          context "with applicable scoped enabled" do
            setup do
              post :create,
                params: { name: "gem-scoped-key", push_rubygem: "true", rubygem_name: @ownership.rubygem.name },
                format: "text"
            end

            should_return_api_key_successfully

            should "have a rubygem associated" do
              created_key = @user.api_keys.find_by(name: "gem-scoped-key")

              assert_equal @ownership.rubygem, created_key.rubygem
            end
          end

          context "with applicable scoped disabled" do
            setup do
              post :create,
                params: { name: "gem-scoped-key", index_rubygems: "true", rubygem_name: @ownership.rubygem.name },
                format: "text"
            end

            should respond_with :unprocessable_content

            should "respond with an error" do
              assert_equal "Rubygem scope can only be set for push/yank rubygem, and add/remove owner scopes", response.body
            end
          end
        end

        context "with an rubygem name that the user is not an owner of" do
          setup do
            post :create,
              params: { name: "gem-scoped-key", index_rubygems: "true", rubygem_name: "invalid-gem-name" },
              format: "text"
          end

          should respond_with :unprocessable_content

          should "respond with an error" do
            assert_equal "Rubygem could not be found", response.body
          end
        end
      end
    end

    context "when a user provides an OTP code" do
      setup do
        @user = create(:user)
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
        authorize_with("#{@user.email}:#{@user.password}")
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
        post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
      end

      should_return_api_key_successfully
    end

    context "when a user has webauthn enabled and no totp code is provided" do
      setup do
        @user = create(:user)
        @webauthn_credential = create(:webauthn_credential, user: @user)
        authorize_with("#{@user.email}:#{@user.password}")
        post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
      end

      should_deny_access_missing_otp
    end

    context "when a user has webauthn enabled and totp code is provided" do
      setup do
        @user = create(:user)
        @webauthn_credential = create(:webauthn_credential, user: @user)
        @verification = create(:webauthn_verification, user: @user)
        authorize_with("#{@user.email}:#{@user.password}")
        @request.env["HTTP_OTP"] = @verification.otp
        post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
      end

      should_return_api_key_successfully
    end

    context "when a user has webauthn enabled and totp code is provided but invalid" do
      setup do
        @user = create(:user)
        @webauthn_credential = create(:webauthn_credential, user: @user)
        @verification = create(:webauthn_verification, user: @user)
        authorize_with("#{@user.email}:#{@user.password}")
        @request.env["HTTP_OTP"] = "123456"
        post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
      end

      should_deny_access_incorrect_otp
    end

    context "when user has enabled MFA for UI and API" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_create
    end

    context "when user has enabled MFA for UI and gem signin" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_create
    end

    context "when mfa is required" do
      setup do
        User.any_instance.stubs(:mfa_required?).returns true
        authorize_with("#{@user.email}:#{@user.password}")
      end

      context "by user with mfa disabled" do
        setup do
          post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
        end

        should "deny access" do
          assert_response :forbidden
          mfa_error = I18n.t("multifactor_auths.api.mfa_required_not_yet_enabled").chomp

          assert_match mfa_error, @response.body
        end
      end

      context "by user on `ui_only` level" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
          post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
        end

        should "deny access" do
          assert_response :forbidden
          mfa_error = I18n.t("multifactor_auths.api.mfa_required_weak_level_enabled").chomp

          assert_match mfa_error, @response.body
        end
      end

      context "by user on `ui_and_gem_signin` level" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
          post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
        end

        should_expect_otp_for_create

        should "not show error message" do
          refute_includes @response.body, "For protection of your account and your gems"
        end
      end

      context "by user on `ui_and_api` level" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
        end

        should_expect_otp_for_create

        should "not show error message" do
          refute_includes @response.body, "For protection of your account and your gems"
        end
      end
    end

    context "expiration" do
      setup do
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should "not allow setting expiration in the past" do
        assert_no_difference -> { @user.api_keys.count } do
          post :create, params: { name: "test-key", index_rubygems: "true", expires_at: 1.day.ago }, format: "text"

          assert_response :unprocessable_content
        end
      end

      should "allow setting expiration in the future" do
        expires_at = 1.day.from_now
        post :create, params: { name: "test-key", index_rubygems: "true", expires_at: }, format: "text"

        assert_response :success

        assert_equal expires_at.change(usec: 0), @user.api_keys.last.expires_at
      end
    end
  end

  context "on PUT to update" do
    setup { @user = create(:user) }

    context "with no credentials" do
      setup { put :update }
      should_deny_access
    end

    context "with bad credentials" do
      setup do
        authorize_with("bad:creds")
        put :update
      end
      should_deny_access
    end

    context "with correct credentials" do
      setup do
        @api_key = create(:api_key, owner: @user, key: "12345", scopes: %i[push_rubygem])
        authorize_with("#{@user.email}:#{@user.password}")
      end

      context "on successful save" do
        setup do
          put :update, params: { api_key: "12345", index_rubygems: "true", mfa: "true" }
          @api_key.reload
        end

        should respond_with :success
        should "keep current scope enabled and update scope in params" do
          assert_predicate @api_key, :can_index_rubygems?
          assert_predicate @api_key, :can_push_rubygem?
        end

        should "update MFA" do
          assert @api_key.mfa
        end
      end

      context "on unsuccessful save" do
        setup do
          put :update, params: { api_key: "12345", push_rubygem: "true", show_dashboard: "true" }
          @api_key.reload
        end

        should respond_with :unprocessable_content

        should "not update api key" do
          refute_predicate @api_key, :can_show_dashboard?
        end

        should "respond with error message" do
          error = "Failed to update scopes for the API key ci-key: [\"Show dashboard scope must be enabled exclusively\"]"

          assert_equal @response.body, error
        end
      end

      context "expiration" do
        should "not allow updating expiration" do
          @api_key.update!(expires_at: 1.month.from_now)
          assert_no_changes -> { @api_key.expires_at } do
            put :update, params: { api_key: "12345", expires_at: 1.day.from_now }
          end
        end

        should "not allow adding expiration" do
          assert_no_changes -> { @api_key.expires_at } do
            put :update, params: { api_key: "12345", expires_at: 1.day.from_now }
          end
        end
      end
    end

    context "when user has enabled MFA for UI and API" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_update
    end

    context "when user has enabled MFA for UI and gem signin" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_update
    end
  end

  context "Datadog AppSec login tracking" do
    setup do
      @user = create(:user)
      @password = @user.password
    end

    should "track success for the user's hashed handle once a key is created" do
      authorize_with("#{@user.email}:#{@password}")
      span = assert_difference -> { @user.api_keys.count }, 1 do
        with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }
      end

      assert_response :success
      assert_equal "true", span.get_tag("appsec.events.users.login.success.track")
      assert_equal({ track_user_login_success: 1 }, @login_event_calls)
      assert_equal Digest::SHA256.hexdigest(@user.handle), span.get_tag("appsec.events.users.login.success.usr.login")
      assert_equal @user.id.to_s, span.get_tag("usr.id")
      assert_nil span.get_tag("appsec.events.users.login.failure.track")
      refute_tags_include(span, @password, @user.email, @user.handle, @response.body)
    end

    should "track success only after a correct OTP" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
      authorize_with("#{@user.handle}:#{@password}")
      @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
      span = with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }

      assert_response :success
      assert_equal "true", span.get_tag("appsec.events.users.login.success.track")
      assert_equal({ track_user_login_success: 1 }, @login_event_calls)
      assert_equal @user.id.to_s, span.get_tag("usr.id")
    end

    should "track success when updating a key" do
      api_key = create(:api_key, owner: @user, key: "12345", scopes: %i[push_rubygem])
      authorize_with("#{@user.email}:#{@password}")
      span = with_appsec_trace { put :update, params: { api_key: "12345", index_rubygems: "true" } }

      assert_response :success
      assert_predicate api_key.reload, :can_index_rubygems?
      assert_equal "true", span.get_tag("appsec.events.users.login.success.track")
      assert_equal({ track_user_login_success: 1 }, @login_event_calls)
      assert_equal @user.id.to_s, span.get_tag("usr.id")
    end

    should "track failure for an existing user with a wrong password and create no key" do
      authorize_with("#{@user.email}:wrong-password")
      span = assert_no_difference [-> { ApiKey.count }, -> { enqueued_jobs.size }, -> { ActionMailer::Base.deliveries.size }] do
        with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }
      end

      assert_response :unauthorized
      assert_match "HTTP Basic: Access denied.", @response.body
      assert_login_failure_tracked(span, login: @user.handle, user: @user, reason: "invalid_credentials")
      refute_tags_include(span, "wrong-password", @user.email)
    end

    should "track failure for an unknown user" do
      authorize_with("nobody@example.com:#{@password}")
      span = assert_no_difference [-> { ApiKey.count }, -> { enqueued_jobs.size }, -> { ActionMailer::Base.deliveries.size }] do
        with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }
      end

      assert_response :unauthorized
      assert_login_failure_tracked(span, login: "nobody@example.com", reason: "invalid_credentials")
      refute_tags_include(span, @password)
    end

    should "track failure, not success, when the password is right but the OTP is missing" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
      authorize_with("#{@user.email}:#{@password}")
      span = assert_no_difference [-> { ApiKey.count }, -> { enqueued_jobs.size }, -> { ActionMailer::Base.deliveries.size }] do
        with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }
      end

      assert_response :unauthorized
      assert_match I18n.t("otp_missing"), @response.body
      assert_login_failure_tracked(span, login: @user.handle, user: @user, reason: "otp_missing")
    end

    should "track failure, not success, when the OTP is wrong on update and change nothing" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
      api_key = create(:api_key, owner: @user, key: "12345", scopes: %i[push_rubygem])
      authorize_with("#{@user.email}:#{@password}")
      @request.env["HTTP_OTP"] = "11111"
      span = assert_no_changes -> { [api_key.reload.attributes, enqueued_jobs.size, ActionMailer::Base.deliveries.size] } do
        with_appsec_trace { put :update, params: { api_key: "12345", index_rubygems: "true" } }
      end

      assert_response :unauthorized
      assert_match I18n.t("otp_incorrect"), @response.body
      assert_login_failure_tracked(span, login: @user.handle, user: @user, reason: "otp_incorrect")
    end

    should "track failure, not success, for an unconfirmed email" do
      user = create(:user, :unconfirmed)
      authorize_with("#{user.email}:#{user.password}")
      span = assert_no_difference [-> { ApiKey.count }, -> { enqueued_jobs.size }, -> { ActionMailer::Base.deliveries.size }] do
        with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }
      end

      assert_response :forbidden
      assert_login_failure_tracked(span, login: user.handle, user:, reason: "email_not_confirmed")
    end

    should "track failure, not success, when required MFA is not enabled" do
      User.any_instance.stubs(:mfa_required?).returns true
      authorize_with("#{@user.email}:#{@password}")
      span = assert_no_difference [-> { ApiKey.count }, -> { enqueued_jobs.size }, -> { ActionMailer::Base.deliveries.size }] do
        with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }
      end

      assert_response :forbidden
      assert_login_failure_tracked(span, login: @user.handle, user: @user, reason: "mfa_required_not_yet_enabled")
    end

    should "track failure, not success, when required MFA is at a weak level" do
      User.any_instance.stubs(:mfa_required?).returns true
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
      authorize_with("#{@user.email}:#{@password}")
      span = assert_no_difference [-> { ApiKey.count }, -> { enqueued_jobs.size }, -> { ActionMailer::Base.deliveries.size }] do
        with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }
      end

      assert_response :forbidden
      assert_login_failure_tracked(span, login: @user.handle, user: @user, reason: "mfa_required_weak_level_enabled")
    end

    should "not track a login for a request authorized with an API key" do
      create(:api_key, owner: @user, key: "12345", scopes: %i[push_rubygem])
      @request.env["HTTP_AUTHORIZATION"] = "12345"
      span = assert_no_difference [-> { ApiKey.count }, -> { enqueued_jobs.size }, -> { ActionMailer::Base.deliveries.size }] do
        with_appsec_trace { post :create, params: { name: "test", index_rubygems: "true" } }
      end

      assert_response :unauthorized
      refute_login_tracked(span)
    end
  end

  context "Datadog API key lifecycle events" do
    setup { @user = create(:user) }

    context "on POST to create" do
      should "track a created key with its owner and scopes but not its secret" do
        ownership = create(:ownership, user: @user)
        authorize_with("#{@user.email}:#{@user.password}")
        span = with_appsec_trace do
          post :create, params: { name: "test-key", push_rubygem: "true", mfa: "true", rubygem_name: ownership.rubygem.name }, format: "text"
        end
        api_key = @user.api_keys.sole
        event = "appsec.events.api_key.create.success"
        tags = appsec_event_family_tags(span, "api_key.")

        assert_equal({ "api_key.create.success" => 1 }, @appsec_event_calls)

        assert_response :success
        assert_equal "true", tags["#{event}.track"]
        assert_equal @user.id.to_s, tags["#{event}.usr.id"]
        assert_equal @user.to_gid.to_s, tags["#{event}.actor.gid"]
        assert_equal api_key.to_gid.to_s, tags["#{event}.api_key.gid"]
        assert_equal "push_rubygem", tags["#{event}.api_key.scopes"]
        assert_equal ownership.rubygem.name, tags["#{event}.api_key.gem"]
        assert_equal "true", tags["#{event}.api_key.mfa"]
        assert_empty tags.keys.grep_v(/\A#{Regexp.escape(event)}\./), "only one lifecycle event is tracked"
        secrets = [@response.body, api_key.hashed_key, @user.password]

        assert_empty(tags.values.map(&:to_s).select { |value| secrets.any? { value.include?(it) } })
      end

      should "not track a create that fails validation" do
        authorize_with("#{@user.email}:#{@user.password}")
        span = with_appsec_trace { post :create, params: { name: "test-key", index_rubygems: "true", show_dashboard: "true" }, format: "text" }

        assert_response :unprocessable_content
        assert_empty @user.api_keys
        assert_empty appsec_event_family_tags(span, "api_key.")
      end

      {
        "a wrong password" => -> { authorize_with("#{@user.email}:wrong-password") },
        "a missing OTP" => lambda {
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          authorize_with("#{@user.email}:#{@user.password}")
        },
        "an incorrect OTP" => lambda {
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          authorize_with("#{@user.email}:#{@user.password}")
          @request.env["HTTP_OTP"] = "11111"
        }
      }.each do |label, deny|
        should "not create or track a key with #{label}" do
          instance_exec(&deny)
          span = assert_no_changes -> { [enqueued_jobs.size, ActionMailer::Base.deliveries.size] } do
            with_appsec_trace { post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text" }
          end

          assert_response :unauthorized
          assert_empty @user.api_keys
          assert_empty appsec_event_family_tags(span, "api_key.")
        end
      end

      should "not create or track a key for an unconfirmed user" do
        @user = create(:user, :unconfirmed)
        authorize_with("#{@user.email}:#{@user.password}")
        span = assert_no_changes -> { [enqueued_jobs.size, ActionMailer::Base.deliveries.size] } do
          with_appsec_trace { post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text" }
        end

        assert_response :forbidden
        assert_empty @user.api_keys
        assert_empty appsec_event_family_tags(span, "api_key.")
      end

      should "not create or track a key when MFA is required but not enabled" do
        User.any_instance.stubs(:mfa_required?).returns(true)
        authorize_with("#{@user.email}:#{@user.password}")
        span = assert_no_changes -> { [enqueued_jobs.size, ActionMailer::Base.deliveries.size] } do
          with_appsec_trace { post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text" }
        end

        assert_response :forbidden
        assert_empty @user.api_keys
        assert_empty appsec_event_family_tags(span, "api_key.")
      end
    end

    context "on PUT to update" do
      setup do
        @api_key = create(:api_key, owner: @user, key: "rubygems_update_secret", scopes: %i[push_rubygem])
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should "track added scopes with the previous scopes" do
        span = with_appsec_trace { put :update, params: { api_key: "rubygems_update_secret", index_rubygems: "true" } }
        event = "appsec.events.api_key.scope_change.success"
        tags = appsec_event_family_tags(span, "api_key.")

        assert_equal({ "api_key.scope_change.success" => 1 }, @appsec_event_calls)

        assert_response :success
        assert_equal "true", tags["#{event}.track"]
        assert_equal @user.id.to_s, tags["#{event}.usr.id"]
        assert_equal @user.to_gid.to_s, tags["#{event}.actor.gid"]
        assert_equal @api_key.to_gid.to_s, tags["#{event}.api_key.gid"]
        assert_equal "index_rubygems,push_rubygem", tags["#{event}.api_key.scopes"]
        assert_equal "push_rubygem", tags["#{event}.api_key.previous_scopes"]
        assert_empty tags.keys.grep_v(/\A#{Regexp.escape(event)}\./)
        secrets = ["rubygems_update_secret", @api_key.hashed_key, @user.password]

        assert_empty(tags.values.map(&:to_s).select { |value| secrets.any? { value.include?(it) } })
      end

      should "not track an update that only changes mfa" do
        span = with_appsec_trace { put :update, params: { api_key: "rubygems_update_secret", mfa: "true" } }

        assert_response :success
        assert @api_key.reload.mfa
        assert_empty appsec_event_family_tags(span, "api_key.")
      end

      should "not track an update that fails validation" do
        span = with_appsec_trace { put :update, params: { api_key: "rubygems_update_secret", show_dashboard: "true" } }

        assert_response :unprocessable_content
        assert_equal %i[push_rubygem], @api_key.reload.scopes
        assert_empty appsec_event_family_tags(span, "api_key.")
      end

      should "not update or track another user's key" do
        other_key = create(:api_key, key: "67890", scopes: %i[push_rubygem])
        span = assert_no_changes -> { [enqueued_jobs.size, ActionMailer::Base.deliveries.size] } do
          with_appsec_trace { put :update, params: { api_key: "67890", index_rubygems: "true" } }
        end

        assert_response :not_found
        assert_equal %i[push_rubygem], other_key.reload.scopes
        assert_empty appsec_event_family_tags(span, "api_key.")
      end

      should "not update or track with a wrong password" do
        authorize_with("#{@user.email}:wrong-password")
        span = assert_no_changes -> { [enqueued_jobs.size, ActionMailer::Base.deliveries.size] } do
          with_appsec_trace { put :update, params: { api_key: "rubygems_update_secret", index_rubygems: "true" } }
        end

        assert_response :unauthorized
        assert_equal %i[push_rubygem], @api_key.reload.scopes
        assert_empty appsec_event_family_tags(span, "api_key.")
      end

      should "not update or track with a missing OTP" do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        span = assert_no_changes -> { [enqueued_jobs.size, ActionMailer::Base.deliveries.size] } do
          with_appsec_trace { put :update, params: { api_key: "rubygems_update_secret", index_rubygems: "true" } }
        end

        assert_response :unauthorized
        assert_equal %i[push_rubygem], @api_key.reload.scopes
        assert_empty appsec_event_family_tags(span, "api_key.")
      end
    end
  end
end
