require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @other_user = create(:user)
    @admin = create(:user)
    @maintainer = create(:user)
    @rubygem = create(:rubygem, owners: [@user, @other_user, @admin, @maintainer])
    @other_rubygem = create(:rubygem, owners: [@user, @other_user])

    FeatureFlag.enable_for_actor(FeatureFlag::ORGANIZATIONS, @user)
  end

  test "requires feature flag enablement" do
    with_feature(FeatureFlag::ORGANIZATIONS, enabled: false, actor: @user) do
      visit sign_in_path

      click_link "login as #{@user[:handle]}"

      visit organization_onboarding_path

      assert_no_text "Create an Org"
    end
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

  test "onboarding with outside contributors demotes their ownership to maintainer" do
    outside_contributor = create(:user)
    create(:ownership, user: outside_contributor, rubygem: @rubygem, role: "owner")

    visit sign_in_path

    click_link "login as #{@user[:handle]}"

    visit organization_onboarding_name_path

    find("label", text: "a gem you own").click

    select @rubygem.name, from: "rubygems.org/organizations/"

    click_button "Continue"

    assert_text "Add gems to your Org"

    click_button "Continue"

    assert_text "Manage Members"

    select "Outside Contributor", from: outside_contributor.handle

    click_button "Continue"

    assert_text "Finalize"

    click_button "Create Org"

    visit rubygem_owners_path(@rubygem.slug)

    assert_text "Please confirm your password to continue"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD

    click_button "Confirm"

    # headers:               OWNER                STATUS     MFA                         ADDED BY                               ROLE
    assert_text "#{outside_contributor.handle}\nConfirmed\nDisabled\n#{outside_contributor.ownerships.first.authorizer_name} Maintainer"
  end
end
