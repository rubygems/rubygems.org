# frozen_string_literal: true

require "application_system_test_case"

class SignUpTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "sign up" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."
    assert_event Events::UserEvent::CREATED, { email: "email@person.com" },
      User.find_by(handle: "nick").events.where(tag: Events::UserEvent::CREATED).sole
  end

  test "sign up stores original email casing" do
    visit sign_up_path

    fill_in "Email", with: "Email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."

    assert_equal "Email@person.com", User.last.email
  end

  test "sign up with bad handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "thisusernameiswaytoolongseriouslywaytoolong"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert_text "error prohibited"
  end

  test "sign up with someone else's handle" do
    create(:user, handle: "nick")
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert_text "error prohibited"
  end

  test "sign up when sign up is disabled" do
    Clearance.configure { |config| config.allow_sign_up = false }
    Rails.application.reload_routes!

    visit root_path

    assert_link "Sign up"

    click_on "Sign up"

    assert_text "New account registration has been temporarily disabled."
    assert_no_button "Sign up"
  end

  test "email confirmation" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      click_button "Sign up"

      assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."
    end

    link = last_email_link

    refute_nil link
    visit_from_cross_site link

    assert_current_path update_email_confirmations_path, ignore_query: true
    assert_text "Confirm email address"
    refute_predicate User.find_by!(handle: "nick"), :email_confirmed?

    click_button "Confirm email address"

    assert_text "Sign in"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"

    fill_in "Email or Username", with: "email@person.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert_text "Dashboard"
  end

  test "links to terms of service" do
    visit sign_up_path

    assert page.has_link? "RubyGems Terms of Service", href: "/policies/terms-of-service"
  end

  teardown do
    Clearance.configure { |config| config.allow_sign_up = true }
    Rails.application.reload_routes!
  end

  private

  def visit_from_cross_site(url)
    server = Capybara.current_session.server
    target = URI(url)
    target_url = "http://localhost:#{server.port}#{target.request_uri}"

    page.driver.with_playwright_page do |pw_page|
      pw_page.goto("http://127.0.0.1:#{server.port}")
      pw_page.set_content <<~HTML
        <a href="#{ERB::Util.html_escape(target_url)}">Open email confirmation</a>
      HTML
      pw_page.get_by_role("link", name: "Open email confirmation").click
    end
  end
end
