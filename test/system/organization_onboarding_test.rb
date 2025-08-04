require "application_system_test_case"

class OrganizationOnboardingSystemTest < ApplicationSystemTestCase
  setup do
    @owner = create(:user)
    @gem_with_reserved_org_name = create(:rubygem, name: "admin", owners: [@owner])
    @gem_with_valid_org_name = create(:rubygem, name: "super_great_gem", owners: [@owner])

    FeatureFlag.enable_for_actor(FeatureFlag::ORGANIZATIONS, @owner)
  end

  test "shows error when trying to create organization with reserved handle" do
    sign_in(@owner)

    visit organization_onboarding_name_path

    assert_text "Name your Organization"

    select @gem_with_reserved_org_name.name, from: "rubygems.org/organizations/"

    click_on "Continue"

    assert_text "is reserved and cannot be used"
    assert_current_path organization_onboarding_name_path
  end

  test "allows creating organization with valid handle" do
    sign_in(@owner)

    visit organization_onboarding_name_path

    assert_text "Name your Organization"

    select @gem_with_valid_org_name.name, from: "rubygems.org/organizations/"

    click_on "Continue"

    refute_text "is reserved and cannot be used"
    assert_current_path organization_onboarding_gems_path
  end
end
