# frozen_string_literal: true

require "application_system_test_case"

class ProfileTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user, email: "nick@rubygems-test.org", password: PasswordHelpers::SECURE_TEST_PASSWORD, handle: "nick1", mail_fails: 1)
  end

  test "changing handle" do
    sign_in

    visit profile_path("nick1")

    assert_text "nick1"

    click_link "Edit Profile"
    fill_in "user_handle", with: "nick2"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert_equal "nick2", page.find_field("user_handle").value
  end

  test "changing to an existing handle" do
    create(:user, email: "nick2@rubygems-test.org", handle: "nick2")

    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "user_handle", with: "nick2"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert_text "Username has already been taken"
  end

  test "changing to invalid handle does not affect rendering" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "user_handle", with: "nick1" * 10
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert_text "Username is too long (maximum is 40 characters)"
    assert page.has_link?("nick1", href: "/profiles/nick1")
  end

  test "changing email does not change email and asks to confirm email" do
    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Email address", with: "nick2@rubygems-test.org"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      click_button "Update"
    end

    assert page.has_selector? "input[value='nick@rubygems-test.org']"
    assert page.has_selector? "#flash_notice", text: "You will receive " \
                                                     "an email within the next few minutes. It contains instructions " \
                                                     "for confirming your new email address."

    assert_event Events::UserEvent::EMAIL_ADDED, { email: "nick2@rubygems-test.org" },
      @user.events.where(tag: Events::UserEvent::EMAIL_ADDED).sole

    link = last_email_link

    assert_not_nil link

    assert_changes -> { @user.reload.mail_fails }, from: 1, to: 0 do
      visit link

      assert_text("Your email address has been verified")
      visit edit_profile_path

      assert page.has_selector? "input[value='nick2@rubygems-test.org']"
    end

    assert_event Events::UserEvent::EMAIL_VERIFIED, { email: "nick2@rubygems-test.org" },
      @user.events.where(tag: Events::UserEvent::EMAIL_VERIFIED).sole
  end

  test "enabling email on profile" do
    # email is hidden at public profile by default
    visit profile_path("nick1")

    assert_no_text("Email Me")

    sign_in
    visit profile_path("nick1")
    click_link "Edit Profile"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    check "Show email in public profile"
    click_button "Update"

    assert_text "Your profile was updated."
    sign_out

    visit profile_path("nick1")

    assert_text("Email Me")
  end

  test "adding X(formerly Twitter) username" do
    sign_in
    visit profile_path("nick1")

    click_link "Edit Profile"
    fill_in "user_twitter_username", with: "nick1"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Update"

    assert_text "Your profile was updated."

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

    assert_text "Your profile was updated."
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

    assert_text "Your account deletion request has been enqueued. " \
                "We will send you a confirmation mail when your request has been processed."
  end

  test "deleting profile multiple times" do
    sign_in
    visit delete_profile_path

    accept_confirm do
      fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
      click_button "Confirm"
    end

    assert_text("Your account deletion request has been enqueued.")

    sign_in
    visit delete_profile_path

    2.times { perform_enqueued_jobs }

    accept_confirm do
      fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
      click_button "Confirm"
    end

    assert_no_enqueued_jobs
  end

  test "seeing owned gems ordered by downloads with their most recent versions" do
    platform_gem = create(:rubygem, name: "platform-gem", owners: [@user], downloads: 7)
    platform_release = create(:version,
      rubygem: platform_gem,
      number: "2.0.0",
      description: "Current platform gem release",
      created_at: Time.zone.parse("2026-01-03"))
    create(:version, rubygem: platform_gem, number: "3.0.0", platform: "java")

    prerelease_gem = create(:rubygem, name: "prerelease-gem", owners: [@user], downloads: 5)
    stable_release = create(:version,
      rubygem: prerelease_gem,
      number: "1.5.0",
      description: "Current stable release",
      created_at: Time.zone.parse("2026-01-02"))
    create(:version, rubygem: prerelease_gem, number: "2.0.0.pre")
    create(:version, :yanked, rubygem: prerelease_gem, number: "3.0.0")

    simple_gem = create(:rubygem, name: "simple-gem", owners: [@user], downloads: 2)
    simple_release = create(:version,
      rubygem: simple_gem,
      number: "4.0.0",
      description: "Current simple gem release",
      created_at: Time.zone.parse("2026-01-01"))

    sign_in
    visit profile_path("nick1")

    assert_equal %w[platform-gem prerelease-gem simple-gem], page.all("article li h4").map(&:text)

    [
      [platform_gem, platform_release, "7"],
      [prerelease_gem, stable_release, "5"],
      [simple_gem, simple_release, "2"]
    ].each do |rubygem, version, downloads|
      row = page.find("a[href='#{rubygem_path(rubygem.slug)}']")

      assert_equal version.description, row[:title]
      assert_equal version.number, row.find("[data-testid='rubygem-version']").text
      assert_equal downloads, row.find("[data-testid='rubygem-downloads']").text
      assert_includes row.text, version.created_at.to_date.to_fs(:long)
    end
  end
end
