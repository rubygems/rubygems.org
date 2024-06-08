require "application_system_test_case"

class MultifactorAuthsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "testuser@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "testuser")
    @seed = ROTP::Base32.random_base32
    @totp = ROTP::TOTP.new(@seed)
  end

  teardown do
    @user.disable_totp!
    @authenticator&.remove!
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  context "cache-control" do
    should "setup mfa does not cache OTP setup" do
      sign_in

      register_otp_device

      assert page.has_content? "Recovery codes"

      go_back

      assert page.has_content? "has already been enabled"
      refute page.has_content? "Register a new device"
      refute page.has_content? @otp_key
    end

    should "setup mfa does not cache recovery codes" do
      sign_in

      register_otp_device

      assert page.has_content? "Recovery codes"
      click_link "[ copy ]"
      check "ack"
      click_button "Continue"

      go_back

      refute page.has_content? "Recovery codes"
    end
  end

  context "strong mfa required" do
    setup do
      @rubygem = create(:rubygem)
      create(:ownership, rubygem: @rubygem, user: @user)
      GemDownload.increment(
        Rubygem::MFA_REQUIRED_THRESHOLD + 1,
        rubygem_id: @rubygem.id
      )
    end

    context "with mfa disabled" do
      should "user with mfa disabled gets redirected back to adoptions after setting up mfa" do
        redirect_test_mfa_disabled(adoptions_profile_path)
      end

      should "user with mfa disabled gets redirected back to dashboard pages after setting up mfa" do
        redirect_test_mfa_disabled(dashboard_path)
      end

      should "user with mfa disabled gets redirected back to delete profile pages after setting up mfa" do
        redirect_test_mfa_disabled(delete_profile_path)
      end

      should "user with mfa disabled gets redirected back to edit profile pages after setting up mfa" do
        redirect_test_mfa_disabled(edit_profile_path)
      end

      should "user with mfa disabled gets redirected back to new api keys pages after setting up mfa" do
        redirect_test_mfa_disabled(new_profile_api_key_path) { verify_password }
      end

      should "user with mfa disabled gets redirected back to notifier pages after setting up mfa" do
        redirect_test_mfa_disabled(notifier_path)
      end

      should "user with mfa disabled gets redirected back to profile api keys pages after setting up mfa" do
        create(:api_key, scopes: %i[push_rubygem], owner: @user, ownership: @ownership)
        redirect_test_mfa_disabled(profile_api_keys_path) { verify_password }
      end

      should "user with mfa disabled gets redirected back to verify session pages after setting up mfa" do
        redirect_test_mfa_disabled(verify_session_path)
      end
    end

    context "with weak level mfa" do
      should "user gets redirected back to adoptions after setting up mfa" do
        redirect_test_mfa_weak_level(adoptions_profile_path)
      end

      should "user gets redirected back to dashboard pages after setting up mfa" do
        redirect_test_mfa_weak_level(dashboard_path)
      end

      should "user gets redirected back to delete profile pages after setting up mfa" do
        redirect_test_mfa_weak_level(delete_profile_path)
      end

      should "user gets redirected back to edit profile pages after setting up mfa" do
        redirect_test_mfa_weak_level(edit_profile_path)
      end

      should "user gets redirected back to new api keys pages after setting up mfa" do
        redirect_test_mfa_weak_level(new_profile_api_key_path) { verify_password }
      end

      should "user gets redirected back to notifier pages after setting up mfa" do
        redirect_test_mfa_weak_level(notifier_path)
      end

      should "user gets redirected back to profile api keys pages after setting up mfa" do
        create(:api_key, scopes: %i[push_rubygem], owner: @user, ownership: @ownership)
        redirect_test_mfa_weak_level(profile_api_keys_path) { verify_password }
      end

      should "user gets redirected back to verify session pages after setting up mfa" do
        redirect_test_mfa_weak_level(verify_session_path)
      end
    end
  end

  context "updating mfa level" do
    should "user with otp can change mfa level" do
      sign_in
      @user.enable_totp!(@seed, :ui_and_gem_signin)

      visit edit_settings_path

      assert page.has_content?("UI and gem signin"), "UI and gem signin was not the default level"

      change_auth_level "UI and API (Recommended)"
      fill_in "otp", with: @totp.now
      click_button "Authenticate"

      assert_current_path(edit_settings_path)
      assert page.has_content?("UI and API (Recommended)"), "MFA level was not updated"
    end

    should "user with webauthn can change mfa level" do
      fullscreen_headless_chrome_driver

      sign_in
      visit edit_settings_path

      @authenticator = create_webauthn_credential_while_signed_in

      assert page.has_content?("UI and gem signin"), "UI and gem signin was not the default level"

      change_auth_level "UI and API (Recommended)"

      assert page.has_content? "Multi-factor authentication"
      assert page.has_content? "Security Device"
      click_on "Authenticate with security device"

      assert_current_path(edit_settings_path)
      assert page.has_content?("UI and API (Recommended)"), "MFA level was not updated"
    end
  end

  def redirect_test_mfa_disabled(path)
    sign_in
    visit path

    assert(page.has_content?("you are required to set up multi-factor authentication"))
    assert_current_path(edit_settings_path)

    register_otp_device

    assert page.has_content? "Recovery codes"
    click_link "[ copy ]"
    check "ack"
    click_button "Continue"
    yield if block_given?

    assert_equal path, current_path, "was not redirected back to original destination: #{path}"
  end

  def redirect_test_mfa_weak_level(path)
    sign_in
    @user.enable_totp!(@seed, :ui_only)
    visit path

    assert page.has_content? "Edit settings"

    change_auth_level "UI and gem signin"
    fill_in "otp", with: @totp.now

    click_button "Authenticate"

    yield if block_given?

    assert_equal path, current_path, "was not redirected back to original destination: #{path}"
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  def otp_key
    key_regex = /( (\w{4})){8}/
    page.find_by_id("otp-key").text.match(key_regex)[0].delete("\s")
  end

  def register_otp_device
    visit edit_settings_path
    click_button "Register a new device"
    @otp_key = otp_key
    totp = ROTP::TOTP.new(@otp_key)
    fill_in "otp", with: totp.now
    click_button "Enable"
    @otp_key
  end

  def verify_password
    return unless page.has_css? "#verify_password_password"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"
  end

  def change_auth_level(type)
    page.select type
    click_button "Update"
  end

  def go_back
    page.evaluate_script("window.history.back()")
  end
end
