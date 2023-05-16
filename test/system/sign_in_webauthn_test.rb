require "application_system_test_case"

class SignInWebauthnTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: nil)
    @mfa_user = create(:user, email: "john@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD,
                  mfa_level: :ui_only, otp_seed: "thisisonemfaseed",
                  mfa_recovery_codes: %w[0123456789ab ba9876543210])

    @authenticator = create_webauthn_authenticator
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

  def create_webauthn_authenticator
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
    visit edit_settings_path

    options = ::Selenium::WebDriver::VirtualAuthenticatorOptions.new
    authenticator = page.driver.browser.add_virtual_authenticator(options)
    WebAuthn::PublicKeyCredentialWithAttestation.any_instance.stubs(:verify).returns true

    credential_nickname = "new cred"
    fill_in "Nickname", with: credential_nickname
    click_on "Register device"

    find("div", text: credential_nickname, match: :first)

    find(:css, ".header__popup-link").click
    click_on "Sign out"

    authenticator
  end
end
