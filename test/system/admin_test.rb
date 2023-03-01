require "application_system_test_case"

class AdminTest < ApplicationSystemTestCase
  test "development login as an admin" do
    @admin_user = create(:admin_github_user, :is_admin)

    visit "/admin"
    assert_content("Log in with GitHub")
    assert_content(@admin_user.login)
    click_link @admin_user.login
    assert_content("Welcome to the RubyGems.org admin dashboard!")
  end
end
