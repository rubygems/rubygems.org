require "application_system_test_case"

class OrganizationInviteTest < ApplicationSystemTestCase
  setup do
    @owner = create(:user)
    @member = create(:user)
    @organization = create(:organization, owners: [@owner])
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
