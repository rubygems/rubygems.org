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

  test "enabling multi-factor authentication with valid otp" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    assert page.has_content? "Enabling multi-factor auth"

    totp = ROTP::TOTP.new(mfa_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "Recovery codes"

    click_link "[ copy ]"
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
    enable_mfa
    visit edit_settings_path

    page.fill_in "otp", with: ROTP::TOTP.new(@user.mfa_seed).now
    change_auth_level "Disabled"

    assert page.has_content? "You have not yet enabled OTP based multi-factor authentication."
    css = %(a[href="https://guides.rubygems.org/setting-up-multifactor-authentication"])
    assert page.has_css?(css)
  end

  test "disabling multi-factor authentication with invalid otp" do
    sign_in
    enable_mfa
    visit edit_settings_path

    key = ROTP::Base32.random_base32
    page.fill_in "otp", with: ROTP::TOTP.new(key).now
    change_auth_level "Disabled"

    assert page.has_content? "You have enabled multi-factor authentication."
  end

  test "disabling multi-factor authentication with recovery code" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    totp = ROTP::TOTP.new(mfa_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "Recovery codes"

    recoveries = page.find_by_id("recovery-code-list").text.split

    click_link "[ copy ]"
    check "ack"
    click_button "Continue"
    page.fill_in "otp", with: recoveries.sample
    change_auth_level "Disabled"

    assert page.has_content? "You have not yet enabled OTP based multi-factor authentication."
  end

  test "Clicking MFA continue button without copying recovery codes creates confirm popup" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    totp = ROTP::TOTP.new(mfa_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"
    check "ack"
    confirm_text = page.dismiss_confirm do
      click_button "Continue"
    end
    assert_equal "Leave without copying recovery codes?", confirm_text
    assert_equal page.current_path, multifactor_auth_path
    page.accept_confirm do
      click_button "Continue"
    end
    page.find("h1", text: "Edit settings")
    assert_equal page.current_path, edit_settings_path
  end

  test "Navigating away another way without copying recovery codes creates default leave warning popup" do
    sign_in
    visit edit_settings_path
    click_button "Register a new device"

    totp = ROTP::TOTP.new(mfa_key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    check "ack"
    confirm_text = dismiss_confirm do
      visit root_path
    end
    assert_equal("", confirm_text)
    assert_equal page.current_path, multifactor_auth_path

    accept_confirm do
      visit root_path
    end
    assert_equal page.current_path, root_path
  end

  test "shows 'ui only' if user's level is ui_only" do
    sign_in
    enable_mfa
    visit edit_settings_path

    assert page.has_selector?("#level > option:nth-child(4)")
    assert page.has_content? "UI Only"
  end

  test "does not shows 'ui only' if user's level is not ui_only" do
    sign_in
    enable_mfa
    visit edit_settings_path

    page.fill_in "otp", with: ROTP::TOTP.new(@user.mfa_seed).now
    change_auth_level "Disabled"

    refute page.has_selector?("#level > option:nth-child(4)")
    refute page.has_content? "UI Only"
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
