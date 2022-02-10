require "test_helper"

class SettingsTest < SystemTest
  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "nick1", mail_fails: 1)
    headless_chrome_driver
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  def enable_mfa
    key = ROTP::Base32.random_base32
    @user.enable_mfa!(key, :ui_only)
  end

  def change_auth_level(type)
    page.select type
    find("#mfa-edit input[type=submit]").click
  end

  def mfa_key
    key_regex = /( (\w{4})){8}/
    page.find_by_id("mfa-key").text.match(key_regex)[0].delete("\s")
  end

  test "enabling multifactor authentication with valid otp" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    assert_text "Enabling multifactor auth"

    totp = ROTP::TOTP.new(mfa_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert_text "Recovery codes"

    click_link "[ copy ]"
    check "ack"
    click_button "Continue"

    assert_text "You have enabled multifactor authentication."
    css = %(a[href="https://guides.rubygems.org/setting-up-multifactor-authentication"])
    assert page.has_css?(css, visible: true)
  end

  test "enabling multifactor authentication with invalid otp" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    assert_text "Enabling multifactor auth"

    totp = ROTP::TOTP.new(ROTP::Base32.random_base32)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert_text "You have not yet enabled multifactor authentication."
  end

  test "disabling multifactor authentication with valid otp" do
    sign_in
    enable_mfa
    visit edit_settings_path

    page.fill_in "otp", with: ROTP::TOTP.new(@user.mfa_seed).now
    change_auth_level "Disabled"

    assert_text "You have not yet enabled multifactor authentication."
    css = %(a[href="https://guides.rubygems.org/setting-up-multifactor-authentication"])
    assert page.has_css?(css)
  end

  test "disabling multifactor authentication with invalid otp" do
    sign_in
    enable_mfa
    visit edit_settings_path

    key = ROTP::Base32.random_base32
    page.fill_in "otp", with: ROTP::TOTP.new(key).now
    change_auth_level "Disabled"

    assert_text "You have enabled multifactor authentication."
  end

  test "disabling multifactor authentication with recovery code" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    totp = ROTP::TOTP.new(mfa_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert_text "Recovery codes"

    recoveries = page.find_by_id("recovery-code-list").text.split

    click_link "[ copy ]"
    check "ack"
    click_button "Continue"
    page.fill_in "otp", with: recoveries.sample
    change_auth_level "Disabled"

    assert_text "You have not yet enabled multifactor authentication."
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
