require "test_helper"

class ProfileTest < SystemTest
  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "nick1", mail_fails: 1)
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  test "changing handle" do
    sign_in

    visit profile_path("nick1")
    assert page.has_content? "nick1"

    click_link "Edit Profile"
    fill_in "Username", with: "nick2"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert page.has_content? "nick2"
  end

  test "changing to an existing handle" do
    create(:user, email: "nick2@example.com", handle: "nick2")

    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Username", with: "nick2"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert page.has_content? "Username has already been taken"
  end

  test "changing to invalid handle does not affect rendering" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Username", with: "nick1" * 10
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert page.has_content? "Username is too long (maximum is 40 characters)"
    assert page.has_link?("nick1", href: "/profiles/nick1")
  end

  test "changing email does not change email and asks to confirm email" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Email address", with: "nick2@example.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD

    click_button "Update"

    assert page.has_selector? "input[value='nick@example.com']"
    assert page.has_selector? "#flash_notice", text: "You will receive "\
                                                     "an email within the next few minutes. It contains instructions "\
                                                     "for confirming your new email address."

    link = last_email_link
    assert_not_nil link

    assert_changes -> { @user.reload.mail_fails }, from: 1, to: 0 do
      visit link

      assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
      visit edit_profile_path
      assert page.has_selector? "input[value='nick2@example.com']"
    end
  end

  test "disabling email on profile" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    check "Hide email in public profile"
    click_button "Update"

    visit profile_path("nick1")
    refute page.has_content?("Email Me")
  end

  test "adding Twitter username" do
    sign_in
    visit profile_path("nick1")

    click_link "Edit Profile"
    fill_in "Twitter username", with: "nick1"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    click_link "Sign out"
    visit profile_path("nick1")

    assert page.has_link?("@nick1", href: "https://twitter.com/nick1")
  end

  test "deleting profile" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    click_button "Delete"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"

    assert page.has_content? "Your account deletion request has been enqueued."\
                             " We will send you a confirmation mail when your request has been processed."
  end

  test "deleting profile multiple times" do
    sign_in
    visit delete_profile_path

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"

    sign_in
    visit delete_profile_path

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"

    Delayed::Worker.new.work_off
    assert_empty Delayed::Job.all
  end

  test "seeing ownership calls and requests" do
    rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
    create(:ownership_call, rubygem: rubygem, user: @user, note: "special note")
    create(:ownership_request, rubygem: rubygem, user: @user, note: "request note")

    sign_in
    visit profile_path("nick1")
    click_link "Adoptions"

    assert page.has_link?(rubygem.name, href: "/gems/#{rubygem.name}")
    assert page.has_content? "special note"
    assert page.has_content? "request note"
  end
end
