require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "nick1", mail_fails: 1)
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  def enable_otp
    key = ROTP::Base32.random_base32
    @user.enable_totp!(key, :ui_only)
  end

  def change_auth_level(type)
    page.select type
    find("#mfa-edit input[type=submit]").click
  end

  def otp_key
    key_regex = /( (\w{4})){8}/
    page.find_by_id("otp-key").text.match(key_regex)[0].delete("\s")
  end

  test "enabling multi-factor authentication with valid otp" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    assert page.has_content? "Enabling multi-factor auth"

    totp = ROTP::TOTP.new(otp_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "Recovery codes"

    click_link "Copy to clipboard"
    check "ack"
    click_button "Continue"

    assert page.has_content? "You have enabled multi-factor authentication."
    css = %(a[href="https://guides.rubygems.org/setting-up-multifactor-authentication"])

    assert page.has_css?(css, visible: true)
  end

  test "enabling multi-factor authentication with invalid otp" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    assert page.has_content? "Enabling multi-factor auth"

    totp = ROTP::TOTP.new(ROTP::Base32.random_base32)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "You have not yet enabled OTP based multi-factor authentication."
  end

  test "disabling multi-factor authentication with valid otp" do
    sign_in
    enable_otp
    visit edit_settings_path

    page.fill_in "otp", with: ROTP::TOTP.new(@user.totp_seed).now
    click_button "Disable"

    assert page.has_content? "You have not yet enabled OTP based multi-factor authentication."
    css = %(a[href="https://guides.rubygems.org/setting-up-multifactor-authentication"])

    assert page.has_css?(css)
  end

  test "disabling multi-factor authentication with invalid otp" do
    sign_in
    enable_otp
    visit edit_settings_path

    key = ROTP::Base32.random_base32
    page.fill_in "otp", with: ROTP::TOTP.new(key).now
    click_button "Disable"

    assert page.has_content? "You have enabled multi-factor authentication."
  end

  test "disabling multi-factor authentication with recovery code" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    totp = ROTP::TOTP.new(otp_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "Recovery codes"

    recoveries = page.find(:css, ".recovery-code-list").value.split

    click_link "Copy to clipboard"
    check "ack"
    click_button "Continue"
    page.fill_in "otp", with: recoveries.sample
    click_button "Disable"

    assert page.has_content? "You have not yet enabled OTP based multi-factor authentication."
  end

  test "Clicking MFA continue button without copying recovery codes creates confirm popup" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    totp = ROTP::TOTP.new(otp_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"
    check "ack"
    confirm_text = page.dismiss_confirm do
      click_button "Continue"
    end

    assert_equal "Leave without copying recovery codes?", confirm_text
    assert_equal recovery_multifactor_auth_path, page.current_path
    page.accept_confirm do
      click_button "Continue"
    end
    page.find("h1", text: "Edit settings")

    assert_equal edit_settings_path, page.current_path
  end

  test "Navigating away another way without copying recovery codes creates default leave warning popup" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    totp = ROTP::TOTP.new(otp_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    check "ack"
    dismiss_confirm("Leave without copying recovery codes?") do
      click_on "Continue"
    end

    assert_equal recovery_multifactor_auth_path, page.current_path

    accept_confirm("Leave without copying recovery codes?") do
      click_on "Continue"
    end

    assert_equal edit_settings_path, page.current_path
  end

  test "shows 'ui only' if user's level is ui_only" do
    sign_in
    enable_otp
    visit edit_settings_path

    assert page.has_selector?("#level > option:nth-child(3)")
    assert page.has_content? "UI Only"
  end

  test "does not shows 'ui only' if user's level is not ui_only" do
    sign_in
    enable_otp
    visit edit_settings_path

    page.fill_in "otp", with: ROTP::TOTP.new(@user.totp_seed).now
    change_auth_level "UI and API"

    refute page.has_selector?("#level > option:nth-child(3)")
    refute page.has_content? "UI Only"
  end
end
