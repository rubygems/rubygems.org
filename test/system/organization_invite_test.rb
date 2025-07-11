require "application_system_test_case"

class OrganizationInviteSystemTest < ApplicationSystemTestCase
  setup do
    @owner = create(:user)
    @member = create(:user)
    @organization = create(:organization, owners: [@owner])

    FeatureFlag.enable_for_actor(:organizations, @owner)
  end

  test "requires feature flag enablement" do
    with_feature(:organizations, enabled: false, actor: @owner) do
      sign_in(@owner)

      visit organization_path(@organization)

      assert_no_text "Invite"
    end
  end

  test "invite user to organization" do
    sign_in(@owner)

    visit organization_path(@organization)

    click_on "Members"
    click_on "Invite"

    fill_in "Handle", with: @member.handle
    select "Maintainer", from: "Role"

    click_on "Invite"

    assert_text "Pending"
  end
end
