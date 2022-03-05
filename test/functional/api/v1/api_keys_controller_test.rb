require "test_helper"

class Api::V1::ApiKeysControllerTest < ActionController::TestCase
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
      refute @controller.request.env[:clearance].signed_in?
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
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
        get :show
        Delayed::Worker.new.work_off
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
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
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
        @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
        @api_key = create(:api_key, user: @user, key: "12345", push_rubygem: true)

        put :update, params: { api_key: "12345", index_rubygems: "true" }
        @api_key.reload
      end

      should respond_with :success
      should "keep current scope enabled and update scope in params" do
        assert @api_key.can_index_rubygems?
        assert @api_key.can_push_rubygem?
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

    context "with correct credentials" do
      setup do
        @user = create(:user)
        authorize_with("#{@user.email}:#{@user.password}")
        get :show, format: "text"
        Delayed::Worker.new.work_off
      end

      should_return_api_key_successfully
      should_deliver_api_key_created_email
      should_not_signin_user
    end

    context "when user has enabled MFA for UI and API" do
      setup do
        @user = create(:user)
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_show
    end

    context "when user has enabled MFA for UI and gem signin" do
      setup do
        @user = create(:user)
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_gem_signin)
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
        post :create, params: { name: "test-key", index_rubygems: "true" }, format: "text"
        Delayed::Worker.new.work_off
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

      context "with MFA param set" do
        setup do
          post :create, params: { name: "mfa", index_rubygems: "true", mfa: "true" }, format: "text"
        end

        should "have MFA" do
          created_key = @user.api_keys.find_by(name: "mfa")
          assert created_key.mfa
        end
      end
    end

    context "when user has enabled MFA for UI and API" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_create
    end

    context "when user has enabled MFA for UI and gem signin" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_gem_signin)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_create
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
        @api_key = create(:api_key, user: @user, key: "12345", push_rubygem: true)
        authorize_with("#{@user.email}:#{@user.password}")
        put :update, params: { api_key: "12345", index_rubygems: "true", mfa: "true" }
        @api_key.reload
      end

      should respond_with :success
      should "keep current scope enabled and update scope in params" do
        assert @api_key.can_index_rubygems?
        assert @api_key.can_push_rubygem?
      end

      should "update MFA" do
        assert @api_key.mfa
      end
    end

    context "when user has enabled MFA for UI and API" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_update
    end

    context "when user has enabled MFA for UI and gem signin" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_gem_signin)
        authorize_with("#{@user.email}:#{@user.password}")
      end

      should_expect_otp_for_update
    end
  end
end
