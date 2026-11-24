# frozen_string_literal: true

require "test_helper"

class WebauthnCredentialsLocaleTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  test "a localized settings page posts security device registration inside that locale" do
    get "/es/settings/edit"

    assert_response :success
    assert_equal "/es/webauthn_credentials", page.find(".js-new-webauthn-credential--form")[:action]
  end

  test "the default settings page posts security device registration without a locale prefix" do
    get "/settings/edit"

    assert_response :success
    assert_equal "/webauthn_credentials", page.find(".js-new-webauthn-credential--form")[:action]
  end

  test "registering a security device keeps the path locale on the flash and recovery redirect" do
    post "/es/webauthn_credentials", headers: { "Accept" => "application/json" }

    assert_response :success
    challenge = response.parsed_body["challenge"]
    origin = WebAuthn.configuration.allowed_origins.first
    client = WebAuthn::FakeClient.new(origin, encoding: false)

    post "/es/webauthn_credentials/callback",
      params: {
        credentials: WebauthnHelpers.create_result(client:, challenge:),
        webauthn_credential: { nickname: "key" }
      },
      as: :json

    assert_equal I18n.t("webauthn_credentials.callback.success", locale: :es), flash[:notice]
    assert_equal recovery_multifactor_auth_url(path_params: { locale: "es" }), response.parsed_body["redirect_url"]
  end
end
