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

  def self.should_respond_to(format, to_meth = :to_s)
    context "with #{format.to_s.upcase} and with confirmed user" do
      setup do
        @user = create(:user)
        authorize_with("#{@user.email}:#{@user.password}")
        get :show, format: format
      end
      should respond_with :success
      should "return API key" do
        response = yield(@response.body)

        assert_not_nil response
        assert_kind_of Hash, response

        hashed_key = @user.api_keys.first.hashed_key

        assert_equal hashed_key, Digest::SHA256.hexdigest(response["rubygems_api_key".send(to_meth)])
      end
    end
  end

  def self.should_deny_access
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  def self.should_deny_access_incorrect_otp
    should "deny access" do
      assert_response 401
      assert_match I18n.t("otp_incorrect"), @response.body
    end
  end

  def self.should_deny_access_missing_otp
    should "deny access" do
      assert_response 401
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

  def self.should_deliver_api_key_created_email
    should "deliver api key created email" do
      refute_empty ActionMailer::Base.deliveries
      email = ActionMailer::Base.deliveries.last

      assert_equal [@user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "New API key created for rubygems.org", email.subject
      assert_match "legacy-key", email.body.to_s
    end
  end

  def self.should_not_signin_user
    should "not sign in user" do
      refute_predicate @controller.request.env[:clearance], :signed_in?
    end
  end

  def self.should_expect_otp_for_show
    context "without OTP" do
      setup { get :show }
      should_deny_access_missing_otp
    end

    context "with incorrect OTP" do
      setup do
        @request.env["HTTP_OTP"] = "11111"
        get :show
      end

      should_deny_access_incorrect_otp
    end

    context "with correct OTP" do
      setup do
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.totp_seed).now
        perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
          get :show
        end
      end

      should_return_api_key_successfully
      should_deliver_api_key_created_email
      should_not_signin_user
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

  context "on GET to show with invalid credentials" do
    setup do
      @user = create(:user)
      authorize_with("bad\0:creds")
      get :show
    end
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  context "on GET to show" do
    should_respond_to(:json) do |body|
      JSON.load body
    end

    should_respond_to(:yaml, :to_sym) do |body|
      YAML.safe_load(body, permitted_classes: [Symbol])
    end

    context "with no credentials" do
      setup { get :show }
      should_deny_access
    end

    context "with bad credentials" do
      setup do
        @user = create(:user)
        authorize_with("bad:creds")
        get :show
      end
      should_deny_access
    end

    context "with credentials with invalid encoding" do
      setup do
        @user = create(:user)
        authorize_with("\x12\xff\x12:creds".force_encoding(Encoding::UTF_8))
        get :show
      end
      should_deny_access
    end

    context "with correct credentials" do
      setup do
        @user = create(:user)
        authorize_with("#{@user.email}:#{@user.password}")
        perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
          get :show, format: "text"
        end
      end

      should_return_api_key_successfully
      should_deliver_api_key_created_email
      should_not_signin_user
    end

    context "when user has enabled MFA for UI and API" do
      setup do
        @user = create(:user)
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_show
    end

    context "when user has enabled MFA for UI and gem signin" do
      setup do
        @user = create(:user)
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_show
    end

    context "when user has old sha1 password" do
      setup do
        @user = create(:user, encrypted_password: "b35e3b6e1b3021e71645b4df8e0a3c7fd98a95fa")
      end

      should "deny access" do
        authorize_with("#{@user.handle}:pass")
        get :show

        assert_response 401
        assert_match "HTTP Basic: Access denied.", @response.body
      end
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
          assert_response 403
          mfa_error = <<~ERROR.chomp
            [ERROR] For protection of your account and your gems, you are required to set up multi-factor authentication \
            at https://rubygems.org/totp/new.

            Please read our blog post for more details (https://blog.rubygems.org/2022/08/15/requiring-mfa-on-popular-gems.html).
          ERROR

          assert_match mfa_error, @response.body
        end
      end

      context "by user on `ui_only` level" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
          post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
        end

        should "deny access" do
          assert_response 403
          mfa_error = <<~ERROR.chomp
            [ERROR] For protection of your account and your gems, you are required to change your MFA level to 'UI and gem signin' or 'UI and API' \
            at https://rubygems.org/settings/edit.

            Please read our blog post for more details (https://blog.rubygems.org/2022/08/15/requiring-mfa-on-popular-gems.html).
          ERROR

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

      context "on unsucessful save" do
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
end
