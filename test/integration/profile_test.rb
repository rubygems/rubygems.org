require 'test_helper'

class ProfileTest < SystemTest
  include EmailHelpers
  include ProfileHelpers

  setup do
    @user = create(:user, email: "nick@example.com", password: "password12345", handle: "nick1")

    page.driver.browser.set_cookie("mfa_feature=true")
  end

  def enable_mfa
    key = ROTP::Base32.random_base32
    @user.enable_mfa!(key, :ui_only)
  end

  def change_auth_level(type)
    page.select type
    find('#mfa-edit input[type=submit]').click
  end

  test "changing handle" do
    sign_in @user

    visit profile_path("nick1")
    assert page.has_content? "nick1"

    click_link "Edit Profile"
    fill_in "Username", with: "nick2"
    fill_in "Password", with: "password12345"
    click_button "Update"

    assert page.has_content? "nick2"
  end

  test "changing to an existing handle" do
    create(:user, email: "nick2@example.com", handle: "nick2")

    sign_in @user
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Username", with: "nick2"
    fill_in "Password", with: "password12345"
    click_button "Update"

    assert page.has_content? "Username has already been taken"
  end

  test "changing to invalid handle does not affect rendering" do
    sign_in @user
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Username", with: "nick1" * 10
    fill_in "Password", with: "password12345"
    click_button "Update"

    assert page.has_content? "Username is too long (maximum is 40 characters)"
    assert page.has_link?("nick1", href: "/profiles/nick1")
  end

  test "changing email does not change email and asks to confirm email" do
    sign_in @user
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Email address", with: "nick2@example.com"
    fill_in "Password", with: "password12345"
    click_button "Update"

    assert page.has_selector? "input[value='nick@example.com']"
    assert page.has_selector? '#flash_notice', text: "You will receive "\
      "an email within the next few minutes. It contains instructions "\
      "for confirming your new email address."

    link = last_email_link
    assert_not_nil link
    visit link

    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
    visit edit_profile_path
    assert page.has_selector? "input[value='nick2@example.com']"
  end

  test "disabling email on profile" do
    sign_in @user
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Password", with: "password12345"
    check "Hide email in public profile"
    click_button "Update"

    visit profile_path("nick1")
    refute page.has_content?("Email Me")
  end

  test "adding Twitter username" do
    sign_in @user
    visit profile_path("nick1")

    click_link "Edit Profile"
    fill_in "Twitter username", with: "nick1"
    fill_in "Password", with: "password12345"
    click_button "Update"

    visit profile_path("nick1")

    assert page.has_link?("@nick1", href: "https://twitter.com/nick1")
  end

  test "deleting profile" do
    sign_in @user
    visit profile_path("nick1")
    click_link "Edit Profile"

    click_button "Delete"
    fill_in "Password", with: "password12345"
    click_button "Confirm"

    assert page.has_content? "Your account deletion request has been enqueued."\
      " We will send you a confrimation mail when your request has been processed."
  end

  test "enabling multifactor authentication with valid otp" do
    sign_in @user
    visit profile_path("nick1")
    click_link "Edit Profile"
    click_button "Register a new device"

    assert page.has_content? "Enabling multifactor auth"

    key_regex = /^Key: (\w{4}) (\w{4}) (\w{4}) (\w{4})/
    key = page.find_by_id("mfa-key").text.match(key_regex)[1..4].join
    totp = ROTP::TOTP.new(key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "Recovery codes"

    click_link "Continue"

    assert page.has_content? "You have enabled multifactor authentication."
  end

  test "enabling multifactor authentication with invalid otp" do
    sign_in @user
    visit profile_path("nick1")
    click_link "Edit Profile"
    click_button "Register a new device"

    assert page.has_content? "Enabling multifactor auth"

    totp = ROTP::TOTP.new(ROTP::Base32.random_base32)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "You have not yet enabled multifactor authentication."
  end

  test "disabling multifactor authentication with valid otp" do
    sign_in @user
    enable_mfa
    visit profile_path("nick1")
    click_link "Edit Profile"

    page.fill_in "otp", with: ROTP::TOTP.new(@user.mfa_seed).now
    change_auth_level "Disabled"

    assert page.has_content? "You have not yet enabled multifactor authentication."
  end

  test "disabling multifactor authentication with invalid otp" do
    sign_in @user
    enable_mfa
    visit profile_path("nick1")
    click_link "Edit Profile"

    key = ROTP::Base32.random_base32
    page.fill_in "otp", with: ROTP::TOTP.new(key).now
    change_auth_level "Disabled"

    assert page.has_content? "You have enabled multifactor authentication."
  end

  test "disabling multifactor authentication with recovery code" do
    sign_in @user
    visit profile_path("nick1")
    click_link "Edit Profile"
    click_button "Register a new device"

    key_regex = /^Key: (\w{4}) (\w{4}) (\w{4}) (\w{4})/
    key = page.find_by_id("mfa-key").text.match(key_regex)[1..4].join
    totp = ROTP::TOTP.new(key)
    page.fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "Recovery codes"

    recoveries = page.find_by_id("recovery-code-list").text.split
    click_link "Continue"
    page.fill_in "otp", with: recoveries.sample
    change_auth_level "Disabled"

    assert page.has_content? "You have not yet enabled multifactor authentication."
  end

  test "listing open and requested adoptions" do
    create(:adoption_request, user: @user, status: "opened", note: "example request")
    create(:adoption, user: @user, note: "example adoption note")

    sign_in @user
    visit profile_path("nick1")
    click_link "Adoptions"

    assert page.has_content? "example request"
    assert page.has_content? "example adoption note"
    assert page.has_button? "Cancel"
    assert page.has_no_button? "Approve"
  end
end
