require "test_helper"

class OwnerIntegrationTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  setup do
    Capybara.current_driver = :rack_test
    @user = create(:user)
    @rubygem = create(:rubygem, number: "1.0.0")
    @ownership = create(:ownership, user: @user, rubygem: @rubygem)
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  test "verify password again after 10 minutes" do
    sign_in_as(@user)
    visit_ownerships_page

    travel 15.minutes

    visit rubygem_path(@rubygem.slug)
    click_link "Ownership"

    assert page.has_field? "Password"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"
  end

  private

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
