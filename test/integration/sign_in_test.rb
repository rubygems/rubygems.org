require "test_helper"

class SignInTest < SystemTest
  setup do
    create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: nil)
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

    assert page.has_content? "Multifactor authentication"

    fill_in "OTP code", with: ROTP::TOTP.new("thisisonemfaseed").now
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end

  test "signing in with invalid otp when mfa enabled" do
    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multifactor authentication"

    fill_in "OTP code", with: "11111"
    click_button "Sign in"

    assert page.has_content? "Sign in"
  end

  test "signing in with valid recovery code when mfa enabled" do
    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multifactor authentication"

    fill_in "OTP code", with: "0123456789ab"
    click_button "Sign in"

    assert page.has_content? "Sign out"
  end

  test "signing in with invalid recovery code when mfa enabled" do
    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multifactor authentication"

    fill_in "OTP code", with: "ab0123456789"
    click_button "Sign in"

    assert page.has_content? "Sign in"
  end

  test "siging in when user does not have handle" do
    @mfa_user.update_attribute(:handle, nil)

    visit sign_in_path
    fill_in "Email or Username", with: "john@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Multifactor authentication"

    fill_in "OTP code", with: ROTP::TOTP.new("thisisonemfaseed").now
    click_button "Sign in"

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
  end
end
