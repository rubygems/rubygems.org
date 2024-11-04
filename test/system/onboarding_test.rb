require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @other_user = create(:user)
    @rubygem = create(:rubygem, owners: [@user, @other_user])
  end

  test "onboarding a gem to an organization" do
    visit sign_in_path

    click_link "login as #{@user[:handle]}"

    visit onboarding_name_path

    fill_in "Name", with: "Test Organization"
    fill_in "Handle", with: @user.handle

    click_button "Save"

    select @rubygem.name, from: "Rubygems"

    click_button "Save"

    # within the div that contains the data-user-handle div
    within "[data-user-handle='#{@other_user.handle}']" do
      select "Owner", from: "Role"
    end

    click_button "Save"

    assert_text "Confirm Organization"

    click_button "Confirm"
  end
end
