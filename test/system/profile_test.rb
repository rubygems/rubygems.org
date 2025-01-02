require "application_system_test_case"
require "test_helper"

class ProfileTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user, email: "nick@example.com", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "nick1", mail_fails: 1)
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  def sign_out
    reset_session!
    visit "/"
  end

  test "changing handle" do
    sign_in

    visit profile_path("nick1")

    assert page.has_content? "nick1"

    click_link "Edit Profile"
    fill_in "user_handle", with: "nick2"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert_equal "nick2", page.find_field("user_handle").value
  end

  test "changing to an existing handle" do
    create(:user, email: "nick2@example.com", handle: "nick2")

    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "user_handle", with: "nick2"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert page.has_content? "Username has already been taken"
  end

  test "changing to invalid handle does not affect rendering" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "user_handle", with: "nick1" * 10
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

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      click_button "Update"
    end

    assert page.has_selector? "input[value='nick@example.com']"
    assert page.has_selector? "#flash_notice", text: "You will receive " \
                                                     "an email within the next few minutes. It contains instructions " \
                                                     "for confirming your new email address."

    assert_event Events::UserEvent::EMAIL_ADDED, { email: "nick2@example.com" },
      @user.events.where(tag: Events::UserEvent::EMAIL_ADDED).sole

    link = last_email_link

    assert_not_nil link

    assert_changes -> { @user.reload.mail_fails }, from: 1, to: 0 do
      visit link

      assert page.has_content?("Your email address has been verified")
      visit edit_profile_path

      assert page.has_selector? "input[value='nick2@example.com']"
    end

    assert_event Events::UserEvent::EMAIL_VERIFIED, { email: "nick2@example.com" },
      @user.events.where(tag: Events::UserEvent::EMAIL_VERIFIED).sole
  end

  test "enabling email on profile" do
    # email is hidden at public profile by default
    visit profile_path("nick1")

    refute page.has_content?("Email Me")

    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    check "Show email in public profile"
    click_button "Update"
    sign_out

    visit profile_path("nick1")

    assert page.has_content?("Email Me")
  end

  test "adding X(formerly Twitter) username" do
    sign_in
    visit profile_path("nick1")

    click_link "Edit Profile"
    fill_in "user_twitter_username", with: "nick1"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    sign_out
    visit profile_path("nick1")

    assert page.has_link?("@nick1", href: "https://twitter.com/nick1")
  end

  test "adding X(formerly Twitter) username without filling in your password" do
    twitter_username = "nick1twitter"

    sign_in
    visit profile_path("nick1")

    click_link "Edit Profile"
    fill_in "user_twitter_username", with: twitter_username

    assert_equal twitter_username, page.find_by_id("user_twitter_username").value

    click_button "Update"

    # Verify that the newly added Twitter username is still on the form so that the user does not need to re-enter it
    assert_equal twitter_username, page.find_by_id("user_twitter_username").value

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert page.has_content? "Your profile was updated."
    assert_equal twitter_username, page.find_by_id("user_twitter_username").value
  end

  test "deleting profile" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    click_button "Delete"
    accept_confirm do
      fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
      click_button "Confirm"
    end

    assert page.has_content? "Your account deletion request has been enqueued. " \
                             "We will send you a confirmation mail when your request has been processed."
  end

  test "deleting profile multiple times" do
    sign_in
    visit delete_profile_path

    accept_confirm do
      fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
      click_button "Confirm"
    end

    sign_in
    visit delete_profile_path

    2.times { perform_enqueued_jobs }

    accept_confirm do
      fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
      click_button "Confirm"
    end

    assert_no_enqueued_jobs
  end

  test "seeing the gems ordered by downloads" do
    create(:rubygem, owners: [@user], number: "1.0.0", downloads: 5)
    create(:rubygem, owners: [@user], number: "1.0.0", downloads: 2)
    create(:rubygem, owners: [@user], number: "1.0.0", downloads: 7)

    sign_in
    visit profile_path("nick1")

    downloads = page.all(".gems__gem__downloads__count")

    assert_equal("7\nDOWNLOADS", downloads[0].text)
    assert_equal("5\nDOWNLOADS", downloads[1].text)
    assert_equal("2\nDOWNLOADS", downloads[2].text)
  end

  test "seeing the latest version when there is a newer previous version" do
    create(:rubygem, owners: [@user], number: "1.0.1")
    create(:version, rubygem: Rubygem.first, number: "0.0.2")

    sign_in
    visit profile_path("nick1")

    version = page.find(".gems__gem__version").text

    assert_equal("1.0.1", version)
  end
end
