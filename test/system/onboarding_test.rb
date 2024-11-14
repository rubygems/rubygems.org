require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @other_user = create(:user)
    @admin = create(:user)
    @maintainer = create(:user)
    @rubygem = create(:rubygem, owners: [@user, @other_user, @admin, @maintainer])
    @other_rubygem = create(:rubygem, owners: [@user, @other_user])
  end

  test "onboarding an organization with a single gem and user" do
    visit sign_in_path

    click_link "login as #{@user[:handle]}"

    visit organization_onboarding_path

    assert_text "Create an Org"

    visit organization_onboarding_name_path

    find("label", text: "a gem you own").click

    select @rubygem.name, from: "rubygems.org/organizations/"

    click_button "Continue"

    assert_text "Add gems to your Org"

    click_button "Continue"

    assert_text "Manage Members"

    click_button "Continue"

    assert_text "Finalize"

    click_button "Create Org"
  end

  test "onboarding an organization with multiple gems and users" do
    visit sign_in_path

    click_link "login as #{@user[:handle]}"

    visit organization_onboarding_name_path

    find("label", text: "a gem you own").click

    select @rubygem.name, from: "rubygems.org/organizations/"

    click_button "Continue"

    assert_text "Add gems to your Org"

    check @other_rubygem.name

    click_button "Continue"

    assert_text "Manage Members"

    select "Owner", from: @other_user.handle

    click_button "Continue"

    assert_text "Finalize"

    click_button "Create Org"
  end

  test "onboarding an organization with many different user roles" do
    visit sign_in_path

    click_link "login as #{@user[:handle]}"

    visit organization_onboarding_name_path

    find("label", text: "a gem you own").click

    select @rubygem.name, from: "rubygems.org/organizations/"

    click_button "Continue"

    assert_text "Add gems to your Org"

    check @other_rubygem.name

    click_button "Continue"

    assert_text "Manage Members"

    select "Owner", from: @other_user.handle
    select "Admin", from: @admin.handle

    click_button "Continue"

    assert_text "Finalize"

    click_button "Create Org"
  end
end
