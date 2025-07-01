require "application_system_test_case"
class AcceptNewPoliciesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, policies_acknowledged_at: nil)
  end
  test "user accepts new policies on default rubygems.org layout" do
    visit sign_in_path

    click_link "login as #{@user[:handle]}"

    visit root_path

    assert_text "New Terms of Service and Privacy Policy"
    click_button "Accept"

    assert_current_path root_path
    assert_no_text "New Terms of Service and Privacy Policy"
  end

  test "user accepts new policies on hammy layout" do
    visit sign_in_path

    click_link "login as #{@user[:handle]}"

    visit dashboard_path

    assert_text "New Terms of Service and Privacy Policy"
    click_button "Accept"

    assert_current_path dashboard_path
    assert_no_text "New Terms of Service and Privacy Policy"
  end
end
