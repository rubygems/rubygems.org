require "test_helper"

class OwnerTest < SystemTest
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
    click_button "Add Owner"
    owners_table = page.find(:css, ".owners__table")
    within_element owners_table do
      assert_selector(:css, "a[href='#{profile_path(@other_user)}']")
    end

    assert_cell(@other_user, "Confirmed", "\u274C")
    assert_cell(@other_user, "Added By", @user.handle)
    assert_cell(@other_user, "Added On", "")

    assert_changes :mails_count, from: 0, to: 1 do
      Delayed::Worker.new.work_off
    end
    assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
  end

  test "adding owner via UI with handle" do
    visit_ownerships_page

    fill_in "Email / Handle", with: @other_user.handle
    click_button "Add Owner"

    assert_cell(@other_user, "Confirmed", "\u274C")
    assert_cell(@other_user, "Added By", @user.handle)

    assert_changes :mails_count, from: 0, to: 1 do
      Delayed::Worker.new.work_off
    end
    assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
  end

  test "owners data is correctly represented" do
    @other_user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
    create(:ownership, :unconfirmed, user: @other_user, rubygem: @rubygem)

    visit_ownerships_page

    assert_cell(@other_user, "Confirmed", "\u274C")
    assert_cell(@other_user, "MFA", "\u2705")

    assert_cell(@user, "Confirmed", "\u2705")
    assert_cell(@user, "MFA", "\u274C")
    assert_cell(@user, "Added On", nice_date_for(@ownership.confirmed_at))
  end

  test "removing owner" do
    create(:ownership, user: @other_user, rubygem: @rubygem)

    visit_ownerships_page

    within_element owner_row(@other_user) do
      click_button "Remove"
    end

    owners_table = page.find(:css, ".owners__table")
    within_element owners_table do
      refute_selector(:css, "a[href='#{profile_path(@other_user)}']")
    end

    assert_changes :mails_count, from: 0, to: 2 do
      Delayed::Worker.new.work_off
    end

    owner_removed_emails = ActionMailer::Base.deliveries.last(2)
    assert_equal "You were removed as an owner to #{@rubygem.name} gem", owner_removed_emails.first.subject
    assert_equal "User #{@other_user.handle} was removed as an owner to #{@rubygem.name} gem", owner_removed_emails.second.subject
  end

  test "removing last owner shows error message" do
    visit_ownerships_page

    within_element owner_row(@user) do
      click_button "Remove"
    end

    assert page.has_selector?("a[href='#{profile_path(@user)}']")
    assert page.has_selector? "#flash_alert", text: "Owner cannot be removed!"

    assert_no_changes :mails_count do
      Delayed::Worker.new.work_off
    end
  end

  test "clicking on confirmation link confirms the account" do
    @unconfirmed_ownership = create(:ownership, :unconfirmed, rubygem: @rubygem)
    confirmation_link = confirm_rubygem_owners_url(@rubygem, token: @unconfirmed_ownership.token)
    visit confirmation_link

    assert_equal page.current_path, rubygem_path(@rubygem)
    assert page.has_selector? "#flash_notice", text: "You are added as an owner to #{@rubygem.name} gem!"

    assert_changes :mails_count, from: 0, to: 2 do
      Delayed::Worker.new.work_off
    end

    owner_added_emails = ActionMailer::Base.deliveries.last(2)
    assert_equal "You were added as an owner to #{@rubygem.name} gem", owner_added_emails.second.subject
    assert_equal "User #{@unconfirmed_ownership.user.handle} was added as an owner to #{@rubygem.name} gem", owner_added_emails.first.subject
  end

  test "clicking on incorrect link shows error" do
    confirmation_link = confirm_rubygem_owners_url(@rubygem, token: SecureRandom.hex(20).encode("UTF-8"))
    visit confirmation_link

    assert page.has_content? "Page not found."

    assert_no_changes :mails_count do
      Delayed::Worker.new.work_off
    end
  end

  test "shows ownership link when is owner" do
    visit rubygem_path(@rubygem)
    assert page.has_selector?("a[href='#{rubygem_owners_path(@rubygem)}']")
  end

  test "hides ownership link when not owner" do
    page.find("a[href='/sign_out']").click
    sign_in_as(@other_user)
    visit rubygem_path(@rubygem)
    refute page.has_selector?("a[href='#{rubygem_owners_path(@rubygem)}']")
  end

  test "hides ownership link when not signed in" do
    page.find("a[href='/sign_out']").click
    visit rubygem_path(@rubygem)
    refute page.has_selector?("a[href='#{rubygem_owners_path(@rubygem)}']")
  end

  test "shows resend confirmation link when unconfirmed" do
    page.find("a[href='/sign_out']").click
    create(:ownership, :unconfirmed, user: @other_user, rubygem: @rubygem)
    sign_in_as(@other_user)
    visit rubygem_path(@rubygem)
    refute page.has_selector?("a[href='#{rubygem_owners_path(@rubygem)}']")
    assert page.has_selector?("a[href='#{resend_confirmation_rubygem_owners_url(@rubygem)}']")
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
    visit rubygem_path(@rubygem)
    click_link "Ownership"
  end

  def sign_in_as(user)
    visit sign_in_path
    fill_in "Email or Username", with: user.email
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"
  end
end
