require "test_helper"

class MultifactorAuthsTest < SystemTest
  setup do
    headless_chrome_driver
    @user = create(:user, email: "testuser@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "testuser")
    @rubygem = create(:rubygem)
    create(:ownership, rubygem: @rubygem, user: @user)
    GemDownload.increment(
      Rubygem::MFA_REQUIRED_THRESHOLD + 1,
      rubygem_id: @rubygem.id
    )
    @seed = ROTP::Base32.random_base32
    @totp = ROTP::TOTP.new(@seed)
  end

  test "user with mfa disabled gets redirected back to adoptions after setting up mfa" do
    redirect_test_mfa_disabled(adoptions_profile_path)
  end

  test "user with mfa disabled gets redirected back to dashboard pages after setting up mfa" do
    redirect_test_mfa_disabled(dashboard_path)
  end

  test "user with mfa disabled gets redirected back to delete profile pages after setting up mfa" do
    redirect_test_mfa_disabled(delete_profile_path)
  end

  test "user with mfa disabled gets redirected back to edit profile pages after setting up mfa" do
    redirect_test_mfa_disabled(edit_profile_path)
  end

  test "user with mfa disabled gets redirected back to new api keys pages after setting up mfa" do
    redirect_test_mfa_disabled(new_profile_api_key_path) { verify_password }
  end

  test "user with mfa disabled gets redirected back to notifier pages after setting up mfa" do
    redirect_test_mfa_disabled(notifier_path)
  end

  test "user with mfa disabled gets redirected back to profile api keys pages after setting up mfa" do
    create(:api_key, push_rubygem: true, user: @user, ownership: @ownership)
    redirect_test_mfa_disabled(profile_api_keys_path) { verify_password }
  end

  test "user with mfa disabled gets redirected back to verify session pages after setting up mfa" do
    redirect_test_mfa_disabled(verify_session_path)
  end

  test "user with weak level mfa gets redirected back to adoptions after setting up mfa" do
    redirect_test_mfa_weak_level(adoptions_profile_path)
  end

  test "user with weak level mfa gets redirected back to dashboard pages after setting up mfa" do
    redirect_test_mfa_weak_level(dashboard_path)
  end

  test "user with weak level mfa gets redirected back to delete profile pages after setting up mfa" do
    redirect_test_mfa_weak_level(delete_profile_path)
  end

  test "user with weak level mfa gets redirected back to edit profile pages after setting up mfa" do
    redirect_test_mfa_weak_level(edit_profile_path)
  end

  test "user with weak level mfa gets redirected back to new api keys pages after setting up mfa" do
    redirect_test_mfa_weak_level(new_profile_api_key_path) { verify_password }
  end

  test "user with weak level mfa gets redirected back to notifier pages after setting up mfa" do
    redirect_test_mfa_weak_level(notifier_path)
  end

  test "user with weak level mfa gets redirected back to profile api keys pages after setting up mfa" do
    create(:api_key, push_rubygem: true, user: @user, ownership: @ownership)
    redirect_test_mfa_weak_level(profile_api_keys_path) { verify_password }
  end

  test "user with weak level mfa gets redirected back to verify session pages after setting up mfa" do
    redirect_test_mfa_weak_level(verify_session_path)
  end

  def redirect_test_mfa_disabled(path)
    sign_in
    visit path
    assert(page.has_content?("Enabling multi-factor auth"), "#{path} was not redirected to mfa setup page")

    totp = ROTP::TOTP.new(mfa_key)
    fill_in "otp", with: totp.now
    click_button "Enable"

    assert page.has_content? "Recovery codes"
    click_link "[ copy ]"
    check "ack"
    click_button "Continue"
    yield if block_given?
    assert_equal path, current_path, "was not redirected back to original destination: #{path}"
  end

  def redirect_test_mfa_weak_level(path)
    sign_in
    @user.enable_mfa!(@seed, :ui_only)
    visit path
    assert page.has_content? "Edit settings"

    fill_in "otp", with: @totp.now
    change_auth_level "UI and gem signin"

    yield if block_given?
    assert_equal path, current_path, "was not redirected back to original destination: #{path}"
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  def mfa_key
    key_regex = /( (\w{4})){8}/
    page.find_by_id("mfa-key").text.match(key_regex)[0].delete("\s")
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

  teardown do
    @user.disable_mfa!
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
