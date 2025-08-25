require "application_system_test_case"

class RubygemTransferSystemTest < ApplicationSystemTestCase
  def setup
    @owner = create(:user)
    @rubygem = create(:rubygem, owners: [@owner])
    @version = create(:version, rubygem: @rubygem)
    @organization = create(:organization, owners: [@owner])
  end

  test "unable to transfer with maintainer role" do
    maintainer = create(:user)
    create(:ownership, rubygem: @rubygem, user: maintainer, role: :maintainer)

    sign_in maintainer

    visit organization_path(@organization.handle)

    assert_no_link "Transfer"
  end

  test "transfer a rubygem to an organization" do
    sign_in @owner

    visit organization_path(@organization.handle)
    click_on "Transfer"

    assert_current_path organization_transfer_rubygems_path

    select @organization.name, from: "Organization"
    click_on "Continue"

    check @rubygem.name
    click_on "Continue"

    assert_text "No owners to manage"

    click_on "Continue"

    assert_text "Review the summary"

    click_on "Transfer Gem"

    assert_text "Successfully transferred 1 gem to #{@organization.name}."
  end

  test "transfer a rubygem to an organization with users" do
    maintainer = create(:user)
    create(:ownership, rubygem: @rubygem, user: maintainer, role: :maintainer)

    sign_in @owner

    visit organization_path(@organization.handle)
    click_on "Transfer"

    assert_current_path organization_transfer_rubygems_path

    select @organization.name, from: "Organization"

    click_on "Continue"

    check @rubygem.name
    click_on "Continue"

    select "Owner", from: maintainer.handle

    click_on "Continue"

    assert_text "Review the summary"

    click_on "Transfer Gem"

    assert_text "Successfully transferred 1 gem to #{@organization.name}."

    visit organization_path(@organization.handle)
    click_on "Members"

    assert_text "#{maintainer.handle} Pending", normalize_ws: true
  end

  test "transfer a rubygem to an organization with outside contributor" do
    maintainer = create(:user)
    create(:ownership, rubygem: @rubygem, user: maintainer, role: :owner)

    sign_in @owner

    visit rubygem_path(@rubygem.slug)

    visit organization_path(@organization.handle)
    click_on "Transfer"

    assert_current_path organization_transfer_rubygems_path

    select @organization.name, from: "Organization"

    click_on "Continue"

    check @rubygem.name
    click_on "Continue"

    select "Outside Contributor", from: maintainer.handle

    click_on "Continue"

    assert_text "Review the summary"

    click_on "Transfer Gem"

    visit rubygem_path(@rubygem.name)

    assert_text "MANAGED BY: #{@organization.name}", normalize_ws: true

    click_on "Owners"

    assert_text "Please confirm your password to continue"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD

    click_button "Confirm"

    # headers:         OWNER             STATUS     MFA                         ADDED BY                      ROLE
    assert_text "#{maintainer.handle}\nConfirmed\nDisabled\n#{maintainer.ownerships.first.authorizer_name} Maintainer"
  end

  test "cancelling a rubygem transfer" do
    sign_in @owner

    visit organization_path(@organization.handle)
    click_on "Transfer"

    assert_current_path organization_transfer_rubygems_path

    select @organization.name, from: "Organization"
    click_on "Cancel"

    assert_current_path dashboard_path
    assert_text "Your draft gem transfer has been cancelled."
  end
end
