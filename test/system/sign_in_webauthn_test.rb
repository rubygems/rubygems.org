require "application_system_test_case"

class SignInWebauthnTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: nil)
    @mfa_user = create(:user, email: "john@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD,
                  mfa_level: :ui_only, mfa_seed: "thisisonemfaseed",
                  mfa_recovery_codes: %w[0123456789ab ba9876543210])

    @authenticator = create_webauthn_credential
  end

  teardown do
    @authenticator.remove!
  end

  test "sign in with webauthn" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"
    assert page.has_content? "Security Device"

    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    click_on "Authenticate with security device"

    assert page.has_content? "Dashboard"
  end

  test "sign in with webauthn but it expired" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"
    assert page.has_content? "Security Device"

    WebAuthn::AuthenticatorAssertionResponse.any_instance.stubs(:verify).returns true

    travel 30.minutes do
      click_on "Authenticate with security device"

      assert page.has_content? "Your login page session has expired."
      assert page.has_content? "Multi-factor authentication"
    end
  end

  test "sign in with webauthn using recovery codes" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"
    assert page.has_content? "Security Device"

    fill_in "otp", with: @user.mfa_recovery_codes.first
    click_button "Verify code"

    assert page.has_content? "Dashboard"
  end
end
