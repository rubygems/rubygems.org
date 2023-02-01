require "test_helper"

class SignInTest < SystemTest
  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: nil)
    @mfa_user = create(:user, email: "john@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD,
                  mfa_level: :ui_only, mfa_seed: "thisisonemfaseed",
                  mfa_recovery_codes: %w[0123456789ab ba9876543210])
  end

  test "signing in" do
    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end

  test "signing in with uppercase email" do
    visit sign_in_path
    fill_in "Email or Username", with: "Nick@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end

  test "signing in with wrong password" do
    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: "wordcrimes12345"
    click_button "Sign in"

    assert page.has_content? "Sign in"
    assert page.has_content? "Bad email or password"
  end

  test "signing in with wrong email" do
    visit sign_in_path
    fill_in "Email or Username", with: "someone@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Sign in"
    assert page.has_content? "Bad email or password"
  end

  test "signing in with unconfirmed email" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    visit sign_in_path
    fill_in "Email or Username", with: "email@person.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Sign in"
    assert page.has_content? "Please confirm your email address with the link sent to your email."
  end

  test "signing in with current valid otp when mfa enabled" do
    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"

    within(".mfa-form") do
      fill_in "OTP or recovery code", with: ROTP::TOTP.new("thisisonemfaseed").now
      click_button "Verify code"
    end

    assert page.has_content? "Sign out"
  end

  test "signing in with current valid otp when mfa enabled but 30 minutes has passed" do
    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"

    travel 30.minutes do
      within(".mfa-form") do
        fill_in "OTP or recovery code", with: ROTP::TOTP.new("thisisonemfaseed").now
        click_button "Verify code"
      end

      assert page.has_content? "Sign in"
      expected_notice = "Your login page session has expired."
      assert page.has_selector? "#flash_notice", text: expected_notice
    end
  end

  test "signing in with invalid otp when mfa enabled" do
    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"

    within(".mfa-form") do
      fill_in "OTP or recovery code", with: "11111"
      click_button "Verify code"
    end

    assert page.has_content? "Sign in"
  end

  test "signing in with valid recovery code when mfa enabled" do
    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"

    within(".mfa-form") do
      fill_in "OTP or recovery code", with: "0123456789ab"
      click_button "Verify code"
    end

    assert page.has_content? "Sign out"
  end

  test "signing in with invalid recovery code when mfa enabled" do
    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"

    within(".mfa-form") do
      fill_in "OTP or recovery code", with: "ab0123456789"
      click_button "Verify code"
    end

    assert page.has_content? "Sign in"
  end

  test "signing in with mfa disabled with gem ownership that exceeds the recommended download threshold" do
    rubygem = create(:rubygem)
    create(:ownership, user: @user, rubygem: rubygem)
    GemDownload.increment(
      Rubygem::MFA_RECOMMENDED_THRESHOLD + 1,
      rubygem_id: rubygem.id
    )

    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    expected_notice = "For protection of your account and your gems, we encourage you to set up multi-factor authentication. " \
                      "Your account will be required to have MFA enabled in the future."
    assert page.has_selector? "#flash_notice", text: expected_notice
    assert_current_path(new_multifactor_auth_path)
    assert page.has_content? "Sign out"
  end

  test "signing in with mfa enabled on `ui_only` with gem ownership that exceeds the recommended download threshold" do
    rubygem = create(:rubygem)
    create(:ownership, user: @mfa_user, rubygem: rubygem)
    GemDownload.increment(
      Rubygem::MFA_RECOMMENDED_THRESHOLD + 1,
      rubygem_id: rubygem.id
    )

    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"

    within(".mfa-form") do
      fill_in "OTP or recovery code", with: "0123456789ab"
      click_button "Verify code"
    end

    expected_notice = "For protection of your account and your gems, we encourage you to change your MFA level " \
                      "to \"UI and gem signin\" or \"UI and API\". Your account will be required to have MFA enabled " \
                      "on one of these levels in the future."
    assert page.has_selector? "#flash_notice", text: expected_notice
    assert_current_path(edit_settings_path)
    assert page.has_content? "Sign out"
  end

  test "signing in with mfa enabled on `ui_and_gem_signin` with gem ownership that exceeds the recommended download threshold" do
    @mfa_user.update!(mfa_level: :ui_and_gem_signin)
    rubygem = create(:rubygem)
    create(:ownership, user: @mfa_user, rubygem: rubygem)
    GemDownload.increment(
      Rubygem::MFA_RECOMMENDED_THRESHOLD + 1,
      rubygem_id: rubygem.id
    )

    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"
    within(".mfa-form") do
      fill_in "OTP or recovery code", with: "0123456789ab"
      click_button "Verify code"
    end

    assert_current_path(dashboard_path)
    refute page.has_selector? "#flash_notice"
    assert page.has_content? "Sign out"
  end

  test "signing in with mfa enabled on `ui_and_api` with gem ownership that exceeds the recommended download threshold" do
    @mfa_user.update!(mfa_level: :ui_and_api)
    rubygem = create(:rubygem)
    create(:ownership, user: @mfa_user, rubygem: rubygem)
    GemDownload.increment(
      Rubygem::MFA_RECOMMENDED_THRESHOLD + 1,
      rubygem_id: rubygem.id
    )

    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"
    within(".mfa-form") do
      fill_in "OTP or recovery code", with: "0123456789ab"
      click_button "Verify code"
    end

    assert_current_path(dashboard_path)
    refute page.has_selector? "#flash_notice"
    assert page.has_content? "Sign out"
  end

  test "siging in when user does not have handle" do
    @mfa_user.update_attribute(:handle, nil)

    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multi-factor authentication"

    within(".mfa-form") do
      fill_in "OTP or recovery code", with: ROTP::TOTP.new("thisisonemfaseed").now
      click_button "Verify code"
    end

    assert page.has_content? "john@example.com"
    assert page.has_content? "Sign out"
  end

  test "signing out" do
    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    click_link "Sign out"

    assert page.has_content? "Sign in"
  end

  test "session expires in two weeks" do
    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    travel 15.days do
      visit edit_profile_path
      assert page.has_content? "Sign in"
    end
  end

  test "sign in to blocked account" do
    User.find_by!(email: "nick@example.com").block!

    visit sign_in_path
    fill_in "Email or Username", with: "nick@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Sign in"
    assert page.has_content? "Your account was blocked by rubygems team. Please email support@rubygems.org to recover your account."
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
