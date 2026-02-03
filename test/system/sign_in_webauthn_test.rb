require "application_system_test_case"

class SignInWebauthnTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: nil)
    @mfa_recovery_codes = %w[0123456789ab ba9876543210]
    @mfa_user = create(:user, email: "john@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD,
                  mfa_level: :ui_only, totp_seed: "thisisonetotpseed",
                  mfa_recovery_codes: @mfa_recovery_codes)

    @authenticator = create_webauthn_credential
  end

  teardown do
    @authenticator&.remove!
    Capybara.use_default_driver
  end

  test "sign in with webauthn mfa" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    assert_text "Multi-factor authentication"
    assert_text "Security Device"

    click_on "Authenticate with security device"

    assert_text "Dashboard"
    assert_no_text "We now support security devices!"
  end

  test "sign in with webauthn mfa but it expired" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    assert_text "Multi-factor authentication"
    assert_text "Security Device"

    travel 30.minutes do
      click_on "Authenticate with security device"

      assert_text "Your login page session has expired."
      assert_text "Sign in"
    end
  end

  test "sign in with webauthn mfa wrong user handle" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    assert_text "Multi-factor authentication"
    assert_text "Security Device"

    @user.update!(webauthn_id: "a")

    click_on "Authenticate with security device"

    assert_no_text "Dashboard"
    assert_text "Sign in"
  end

  test "sign in with webauthn mfa using recovery codes" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"

    assert_text "Multi-factor authentication"
    assert_text "Security Device"

    fill_in "otp", with: @mfa_recovery_codes.first
    click_button "Authenticate"

    assert_text "Dashboard"
  end

  test "sign in with webauthn" do
    visit sign_in_path

    click_on "Authenticate with security device"

    assert_text "Dashboard"
    assert_no_text "We now support security devices!"
  end

  test "sign in with webauthn failure" do
    visit sign_in_path

    @user.webauthn_credentials.find_each { |c| c.update!(external_id: "a") }

    click_on "Authenticate with security device"

    assert_no_text "Dashboard"
  end

  test "sign in with webauthn user_handle changed failure" do
    visit sign_in_path

    @user.update!(webauthn_id: "a")

    click_on "Authenticate with security device"

    assert_no_text "Dashboard"
    assert_text "Sign in"
  end

  test "sign in with webauthn does not expire" do
    visit sign_in_path

    travel 30.minutes do
      click_on "Authenticate with security device"

      assert_text "Dashboard"
    end
  end

  test "sign in with webauthn to blocked account" do
    @user.block!

    visit sign_in_path
    click_on "Authenticate with security device"

    assert_no_text "Dashboard"
    assert_text "Sign in"
    assert_text "Your account was blocked by rubygems team. Please email support@rubygems.org to recover your account."
  end

  test "sign in with webauthn to deleted account" do
    @user.update!(deleted_at: Time.zone.now)

    visit sign_in_path
    click_on "Authenticate with security device"

    assert_no_text "Dashboard"
    assert_text "Sign in"
  end
end
