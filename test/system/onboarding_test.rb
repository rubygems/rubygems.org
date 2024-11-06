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

    select @rubygem.name, from: "organization_onboarding_organization_handle"
    fill_in "Display Name", with: "Test Organization"

    click_button "Save"

    select @rubygem.name, from: "Rubygems"

    click_button "Save"

    # within the div that contains the data-user-handle div
    within "[data-user-handle='#{@other_user.handle}']" do
      select "Admin", from: "Role"
    end

    click_button "Save"

    assert_text "Confirm Organization"

    click_button "Confirm"

    @organization = Organization.find_by(name: "Test Organization")

    assert_includes @user.organizations, @organization
    assert_includes @other_user.organizations, @organization
    assert_predicate @other_user.memberships.find_by(organization: @organization), :admin?
    assert_equal @user.organizations.find_by(name: "Test Organization")
  end
end
