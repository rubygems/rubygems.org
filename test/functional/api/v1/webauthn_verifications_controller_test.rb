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

        travel_to Time.utc(2023, 1, 1, 0, 0, 0) do
          post :create, format: format
        end

        @token = @user.webauthn_verification.path_token
      end

      should respond_with :success

      should "have a body" do
        assert_not_nil @response.body
      end

      if format == :plain
        should "return only the Webauthn verification URL with path token" do
          assert_equal @response.body, "http://test.host/webauthn_verification/#{@token}"
        end
      else
        should "return a YAML or JSON document with path token" do
          response = YAML.safe_load(@response.body)
          assert_equal response["path"], "http://test.host/webauthn_verification/#{@token}"
        end

        should "return a YAML or JSON document with path expiry" do
          response = YAML.safe_load(@response.body)
          assert_equal "2023-01-01T00:02:00.000Z", response["expiry"]
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
