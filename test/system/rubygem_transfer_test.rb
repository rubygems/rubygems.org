require "application_system_test_case"

class RubygemTransferSystemTest < ApplicationSystemTestCase
  def setup
    @owner = create(:user)
    @rubygem = create(:rubygem, owners: [@owner])
    @version = create(:version, rubygem: @rubygem)
    @organization = create(:organization, owners: [@owner])
  end

  test "transfer a rubygem that is not eligible" do
    maintainer = create(:user)
    create(:ownership, rubygem: @rubygem, user: maintainer, role: :maintainer)

    sign_in maintainer

    visit rubygem_path(@rubygem.slug)

    assert_no_link "Transfer to Organization"
  end

  test "transfer a rubygem to an organization" do
    sign_in @owner

    visit rubygem_path(@rubygem.slug)
    click_on "Transfer to Organization"

    assert_current_path rubygem_transfer_organization_path(@rubygem.slug)

    select @organization.name, from: "Organization"
    click_on "Continue"

    assert_text "No owners to manage"

    click_on "Continue"

    assert_text "Review the summary"

    click_on "Transfer Gem"

    assert_text "MANAGED BY: #{@organization.name}", normalize_ws: true
  end

  test "transfer a rubygem to an organization with users" do
    maintainer = create(:user)
    create(:ownership, rubygem: @rubygem, user: maintainer, role: :maintainer)

    sign_in @owner

    visit rubygem_path(@rubygem.slug)

    click_on "Transfer to Organization"

    assert_current_path rubygem_transfer_organization_path(@rubygem.slug)

    select @organization.name, from: "Organization"

    click_on "Continue"

    select "Owner", from: maintainer.handle

    click_on "Continue"

    assert_text "Review the summary"

    click_on "Transfer Gem"

    assert_text "MANAGED BY: #{@organization.name}", normalize_ws: true
  end

  test "transfer a rubygem to an organization with outside contributor" do
    maintainer = create(:user)
    create(:ownership, rubygem: @rubygem, user: maintainer, role: :owner)

    sign_in @owner

    visit rubygem_path(@rubygem.slug)

    click_on "Transfer to Organization"

    assert_current_path rubygem_transfer_organization_path(@rubygem.slug)

    select @organization.name, from: "Organization"

    click_on "Continue"

    select "Outside Contributor", from: maintainer.handle

    click_on "Continue"

    assert_text "Review the summary"

    click_on "Transfer Gem"

    assert_text "MANAGED BY: #{@organization.name}", normalize_ws: true

    # Verify the outside contributor still has ownership but was demoted to maintainer
    ownership = Ownership.find_by(user: maintainer, rubygem: @rubygem)

    assert_not_nil ownership
    assert_equal "maintainer", ownership.role
  end

  test "cancelling a rubygem transfer" do
    sign_in @owner

    visit rubygem_path(@rubygem.slug)
    click_on "Transfer to Organization"

    assert_current_path rubygem_transfer_organization_path(@rubygem.slug)

    select @organization.name, from: "Organization"
    click_on "Cancel"

    assert_current_path rubygem_path(@rubygem.slug)
  end
end
