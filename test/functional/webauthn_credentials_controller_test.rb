require "test_helper"

class WebauthnCredentialsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "#create" do
    context "when logged out" do
      setup do
        post :create
      end

      should redirect_to :sign_in
    end

    context "when logged in" do
      setup do
        @user = create(:user)
        sign_in_as @user
        post :create
        @json = JSON.parse(response.body)
      end

      should "return the user id" do
        assert_not_nil @json["user"]["id"]
      end

      should "return the challenge" do
        assert_not_nil @json["challenge"]
      end

      should "return no excluded credentials" do
        assert_empty @json["excludeCredentials"]
      end

      should "set the challenge in the session" do
        assert_not_nil session[:webauthn_registration]["challenge"]
      end
    end

    context "when having existing credentials" do
      setup do
        @user = create(:user)
        create_list(:webauthn_credential, 3, user: @user)
        sign_in_as @user
        post :create
        @json = JSON.parse(response.body)
      end

      should "return the user id" do
        assert_not_nil @json["user"]["id"]
      end

      should "return the challenge" do
        assert_not_nil @json["challenge"]
      end

      should "return excluded credentials" do
        assert_equal 3, @json["excludeCredentials"].size

        @json["excludeCredentials"].each do |credential|
          assert_not_nil credential["id"]
          assert_not_nil credential["type"]
        end
      end

      should "set the challenge in the session" do
        assert_not_nil session[:webauthn_registration]["challenge"]
      end
    end
  end

  context "#callback" do
    context "when logged out" do
      setup do
        post :callback
      end

      should redirect_to :sign_in
    end

    context "when correctly verifying a challenge" do
      setup do
        @user = create(:user)
        sign_in_as @user
        post :create
        @nickname = SecureRandom.hex
        challenge = JSON.parse(response.body)["challenge"]
        origin = "http://localhost:3000"
        client = WebAuthn::FakeClient.new(origin, encoding: false)

        perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
          post(
            :callback,
            params: {
              credentials: WebauthnHelpers.create_result(
                client: client,
                challenge: challenge
              ),
              webauthn_credential: { nickname: @nickname }
            },
            format: :json
          )
        end
      end

      should redirect_to :edit_settings

      should "create the webauthn credential" do
        assert_equal @nickname, @user.webauthn_credentials.last.nickname
        assert_equal 1, @user.webauthn_credentials.count
      end

      should "deliver webauthn credential added email" do
        assert_equal 1, ActionMailer::Base.deliveries.size
        email = ActionMailer::Base.deliveries.last

        assert_equal [@user.email], email.to
        assert_equal ["no-reply@mailer.rubygems.org"], email.from
        assert_equal "New security device added on RubyGems.org", email.subject
      end
    end

    context "when nickname is not present" do
      setup do
        @user = create(:user)
        sign_in_as @user
        post :create
        @nickname = ""
        challenge = JSON.parse(response.body)["challenge"]
        origin = "http://localhost:3000"
        client = WebAuthn::FakeClient.new(origin, encoding: false)
        post(
          :callback,
          params: {
            credentials: WebauthnHelpers.create_result(
              client: client,
              challenge: challenge
            ),
            webauthn_credential: { nickname: @nickname }
          },
          format: :json
        )
      end

      should respond_with :unprocessable_entity
    end

    context "when challenge is incorrect" do
      setup do
        @user = create(:user)
        sign_in_as @user
        post :create
        @nickname = SecureRandom.hex
        challenge = SecureRandom.hex
        origin = "http://localhost:3000"
        client = WebAuthn::FakeClient.new(origin, encoding: false)
        post(
          :callback,
          params: {
            credentials: WebauthnHelpers.create_result(
              client: client,
              challenge: challenge
            ),
            webauthn_credential: { nickname: @nickname }
          },
          format: :json
        )
      end

      setup { subject }

      should respond_with :unprocessable_entity
    end
  end

  context "#destroy" do
    setup do
      @user = create(:user)
      @credential = create(:webauthn_credential, user: @user)
      sign_in_as @user

      perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
        delete :destroy, params: { id: @credential.id }
      end
    end

    should "destroy the webauthn credential" do
      assert_equal 0, @user.webauthn_credentials.count
    end

    should "set success notice flash" do
      assert_equal "Credential deleted", flash[:notice]
    end

    should "set failure notice flash if destroy fails" do
      @user.stubs(:webauthn_credentials).returns @credential
      WebauthnCredential.any_instance.stubs(:find).returns @credential
      @credential.stubs(:destroy).returns false

      delete :destroy, params: { id: @credential.id }

      refute_nil flash[:error]
    end

    should "deliver webauthn credential removed email" do
      assert_equal 1, ActionMailer::Base.deliveries.size
      email = ActionMailer::Base.deliveries.last

      assert_equal [@user.email], email.to
      assert_equal ["no-reply@mailer.rubygems.org"], email.from
      assert_equal "Security device removed on RubyGems.org", email.subject
    end

    should redirect_to :edit_settings
  end
end
