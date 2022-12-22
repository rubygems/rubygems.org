require "test_helper"

class Api::V1::WebauthnVerificationsControllerTest < ActionController::TestCase
  should "route new paths to new controller" do
    route = { controller: "api/v1/webauthn_verifications", action: "create" }
    assert_recognizes(route, { path: "/api/v1/webauthn_verification", method: :post })
  end

  def authorize_with(str)
    @request.env["HTTP_AUTHORIZATION"] = "Basic #{Base64.encode64(str)}"
  end

  def self.should_respond_to_format(format)
    context "when the request asks for format '#{format}'" do
      setup do
        @user = create(:user)
        create(:webauthn_credential, user: @user)
        authorize_with("#{@user.email}:#{@user.password}")
        post :create, format: format
      end

      should respond_with :success

      should "return Webauthn verification URL with path token" do
        assert_not_nil @response.body

        token = @user.webauthn_verification.path_token

        if format == :plain
          assert_equal @response.body, "example.com/webauthn/#{token}"
        else
          response = YAML.safe_load(@response.body)
          assert_equal response["path"], "example.com/webauthn/#{token}"
        end
      end
    end
  end

  context "on POST to create" do
    context "with no credentials" do
      setup { post :create }
      should "deny access" do
        assert_response 401
        assert_match "HTTP Basic: Access denied.", @response.body
      end
    end

    context "with invalid credentials" do
      setup do
        @user = create(:user)
        create(:webauthn_credential, user: @user)
        authorize_with("bad\0:creds")
        post :create
      end

      should "deny access" do
        assert_response 401
        assert_match "HTTP Basic: Access denied.", @response.body
      end
    end

    context "user has enabled webauthn" do
      should_respond_to_format :yaml
      should_respond_to_format :json
      should_respond_to_format :plain

      should "not sign in user" do
        refute_predicate @controller.request.env[:clearance], :signed_in?
      end
    end

    context "user has not enabled webauthn" do
      setup do
        @user = create(:user)
        authorize_with("#{@user.email}:#{@user.password}")
        post :create
      end

      should respond_with :unprocessable_entity
      should "tell the user they don't have a WebAuthn hardware token" do
        assert_match "You don't have any security devices", response.body
      end
    end
  end
end
