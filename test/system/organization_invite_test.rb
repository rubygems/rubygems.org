require "test_helper"

class OrgnaizationInviteTest < ActionDispatch::SystemTestCase
  setup do
    @owner = create(:user)
    @member = create(:user)
    @organization = create(:organization, owners: [@owner])
  end

  test "invite user to organization" do
    visit sign_in_path

    click_link "login as #{@user[:handle]}"

    visit organization_path(@organization)

    click_on "Members"
    click_on "Invite Member"

    fill_in "Handle", with: @member.handle
    select "Maintainer", from: "Role"

    click_on "Invite"

    assert_text "Pending"
  end
end
