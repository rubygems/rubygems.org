require "application_system_test_case"

class OwnerTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper
  include RubygemsHelper

  setup do
    @user = create(:user)
    @other_user = create(:user)
    @rubygem = create(:rubygem, number: "1.0.0")
    @ownership = create(:ownership, user: @user, rubygem: @rubygem)

    sign_in_as(@user)
  end

  test "adding owner via UI with email" do
    visit_ownerships_page

    fill_in "Email / Handle", with: @other_user.email

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      click_button "Add Owner"
    end

    owners_table = page.find(:css, ".owners__table")

    within_element owners_table do
      assert_selector(:css, "a[href='#{profile_path(@other_user.display_id)}']")
    end

    assert_cell(@other_user, "Confirmed", "Pending")
    assert_cell(@other_user, "Added By", @user.handle)
    assert_cell(@other_user, "Confirmed At", "")

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    assert_emails 1
    assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
  end

  test "adding owner via UI with handle" do
    visit_ownerships_page

    fill_in "Email / Handle", with: @other_user.handle

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      click_button "Add Owner"
    end

    assert_cell(@other_user, "Confirmed", "Pending")
    assert_cell(@other_user, "Added By", @user.handle)

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    assert_emails 1
    assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
  end

  test "owners data is correctly represented" do
    @other_user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    create(:ownership, :unconfirmed, user: @other_user, rubygem: @rubygem)

    visit_ownerships_page

    assert_cell(@other_user, "Confirmed", "Pending")
    within_element owner_row(@other_user) do
      within_element "td[data-title='MFA']" do
        assert_selector "img[src='/images/check.svg']"
      end
    end

    assert_cell(@user, "Confirmed", "Confirmed")
    within_element owner_row(@user) do
      within_element "td[data-title='MFA']" do
        assert_selector "img[src='/images/x.svg']"
      end
    end

    assert_cell(@user, "Confirmed At", @ownership.confirmed_at.strftime("%Y-%m-%d %H:%M %Z"))
  end

  test "removing owner" do
    create(:ownership, user: @other_user, rubygem: @rubygem)

    visit_ownerships_page

    within_element owner_row(@other_user) do
      perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
        click_button "Remove"
      end
    end

    accept_confirm

    refute_selector ".owners__table a[href='#{profile_path(@other_user)}']"

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    assert_emails 1
    assert_contains last_email.subject, "You were removed as an owner from #{@rubygem.name} gem"
    assert_equal [@other_user.email], last_email.to
  end

  test "removing last owner shows error message" do
    visit_ownerships_page

    within_element owner_row(@user) do
      click_button "Remove"
    end

    accept_confirm

    assert_selector("a[href='#{profile_path(@user.display_id)}']")
    assert_selector "#flash_alert", text: "Can't remove the only owner of the gem"

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

    assert_no_emails
  end

  test "verify using webauthn" do
    create_webauthn_credential_while_signed_in

    visit dashboard_path
    click_on "User Dropdown Menu"
    click_link(nil, href: "/sign_out")

    visit sign_in_path
    click_button "Authenticate with security device"
    find(:css, ".header__popup-link")

    visit rubygem_path(@rubygem.slug)
    click_link "Ownership"

    assert_css "#verify_password_password"

    click_button "Authenticate with security device"

    assert_text "add or remove owners"
  end

  test "verify failure using webauthn shows error" do
    create_webauthn_credential_while_signed_in
    visit dashboard_path
    click_on "User Dropdown Menu"
    click_link(nil, href: "/sign_out")

    visit sign_in_path
    click_button "Authenticate with security device"
    find(:css, ".header__popup-link")

    visit rubygem_path(@rubygem.slug)
    click_link "Ownership"

    assert_css "#verify_password_password"

    @user.webauthn_credentials.find_each { |c| c.update!(external_id: "a") }

    click_button "Authenticate with security device"

    assert_text "Credentials required"
    assert_css "#verify_password_password"
  end

  test "verify password again after 10 minutes" do
    visit_ownerships_page
    travel 15.minutes
    visit rubygem_path(@rubygem.slug)
    click_link "Ownership"

    assert_field "Password"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"
  end

  test "incorrect password on verify shows error" do
    visit rubygem_path(@rubygem.slug)
    click_link "Ownership"

    assert_css "#verify_password_password"
    fill_in "Password", with: "wrong password"
    click_button "Confirm"

    assert_selector "#flash_alert", text: "This request was denied. We could not verify your password."
  end

  test "incorrect password error does not persist after correct password" do
    visit rubygem_path(@rubygem.slug)
    click_link "Ownership"

    assert_css "#verify_password_password"
    fill_in "Password", with: "wrong password"
    click_button "Confirm"

    assert_selector "#flash_alert", text: "This request was denied. We could not verify your password."

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"

    assert_no_selector "#flash_alert"
  end

  test "clicking on confirmation link confirms the account" do
    @unconfirmed_ownership = create(:ownership, :unconfirmed, rubygem: @rubygem)
    confirmation_link = confirm_rubygem_owners_url(@rubygem.slug, token: @unconfirmed_ownership.token)

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      visit confirmation_link
    end

    assert_current_path rubygem_path(@rubygem.slug)
    assert_selector "#flash_notice", text: "You were added as an owner to #{@rubygem.name} gem"

    assert_emails 2

    owner_added_email_subjects = ActionMailer::Base.deliveries.map(&:subject)

    assert_contains owner_added_email_subjects, "You were added as an owner to #{@rubygem.name} gem"
    assert_contains owner_added_email_subjects, "User #{@unconfirmed_ownership.user.handle} was added as an owner to #{@rubygem.name} gem"
  end

  test "clicking on incorrect link shows error" do
    confirmation_link = confirm_rubygem_owners_url(@rubygem.slug, token: SecureRandom.hex(20).encode("UTF-8"))
    visit confirmation_link

    assert page.has_content? "Page not found."

    assert_no_emails
  end

  test "shows ownership link when is owner" do
    visit rubygem_path(@rubygem.slug)

    assert_selector("a[href='#{rubygem_owners_path(@rubygem.slug)}']")
  end

  test "hides ownership link when not owner" do
    click_on "User Dropdown Menu"
    page.click_link(nil, href: "/sign_out")
    sign_in_as(@other_user)
    visit rubygem_path(@rubygem.slug)

    assert_no_selector("a[href='#{rubygem_owners_path(@rubygem.slug)}']")
  end

  test "hides ownership link when not signed in" do
    click_on "User Dropdown Menu"
    page.click_link(nil, href: "/sign_out")
    visit rubygem_path(@rubygem.slug)

    assert_no_selector("a[href='#{rubygem_owners_path(@rubygem.slug)}']")
  end

  test "shows resend confirmation link when unconfirmed" do
    click_on "User Dropdown Menu"
    page.click_link(nil, href: "/sign_out")
    create(:ownership, :unconfirmed, user: @other_user, rubygem: @rubygem)
    sign_in_as(@other_user)
    visit rubygem_path(@rubygem.slug)

    assert_no_selector("a[href='#{rubygem_owners_path(@rubygem.slug)}']")
    assert_selector("a[href='#{resend_confirmation_rubygem_owners_path(@rubygem.slug)}']")
  end

  test "deleting unconfirmed owner user" do
    create(:ownership, :unconfirmed, user: @other_user, rubygem: @rubygem)
    @other_user.destroy
    visit_ownerships_page

    refute page.has_content? @other_user.handle
  end

  test "updating user to maintainer role" do
    maintainer = create(:user)
    create(:ownership, user: maintainer, rubygem: @rubygem)

    visit_ownerships_page

    within_element owner_row(maintainer) do
      click_button "Edit"
    end

    select "Maintainer", from: "role"

    click_button "Update"

    assert_cell maintainer, "Role", "Maintainer"
  end

  test "editing the ownership of the current user" do
    visit_ownerships_page

    within_element owner_row(@user) do
      assert_selector "button[disabled]", text: "Edit"
    end
  end

  test "creating new owner with maintainer role" do
    maintainer = create(:user)

    visit_ownerships_page

    fill_in "Handle", with: maintainer.handle
    select "Maintainer", from: "role"

    click_button "Add Owner"

    assert_cell maintainer, "Role", "Maintainer"
  end

  teardown do
    @authenticator&.remove!
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  private

  def owner_row(owner)
    page.find(:css, ".owners__table")
      .find(:css, "td[data-title='Name']", text: /^#{owner.handle}$/)
      .find(:xpath, "./parent::tr")
  end

  def assert_cell(user, column, expected)
    within_element owner_row(user) do
      assert_selector "td[data-title='#{column}']", text: expected
    end
  end

  def visit_ownerships_page
    visit rubygem_path(@rubygem.slug)
    click_link "Ownership"
    return unless page.has_css? "#verify_password_password"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"
  end

  def sign_in_as(user)
    visit sign_in_path
    fill_in "Email or Username", with: user.email
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    find(:css, ".header__popup-link")
  end
end
