# frozen_string_literal: true

require "application_system_test_case"

class Avo::PrefixReservationsSystemTest < ApplicationSystemTestCase
  test "creating a prefix reservation for an organization" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    organization = create(:organization, name: "Acme Corp", handle: "acme-corp")

    visit avo.resources_prefix_reservations_path

    click_on "Create new prefix reservation"

    page.find_by_id("prefix_reservation_prefix", wait: Capybara.default_max_wait_time)
    fill_in "Prefix", with: "acme"
    select "Acme Corp", from: "Organization"
    fill_in "Comment", with: "Reserving the acme prefix for Acme Corp per support ticket"
    click_on "Save"

    page.assert_text "Manual create of PrefixReservation"

    prefix_reservation = PrefixReservation.sole

    assert_equal "acme", prefix_reservation.prefix
    assert_equal organization, prefix_reservation.organization

    audit = Audit.sole

    assert_equal prefix_reservation, audit.auditable
    assert_equal "Manual create of PrefixReservation", audit.action
    assert_equal admin_user, audit.admin_github_user
    assert_equal "Reserving the acme prefix for Acme Corp per support ticket", audit.comment
  end

  test "an invalid prefix is rejected with a visible error" do
    avo_sign_in_as create(:admin_github_user, :is_admin)

    create(:organization, name: "Acme Corp", handle: "acme-corp")

    visit avo.new_resources_prefix_reservation_path

    page.find_by_id("prefix_reservation_prefix", wait: Capybara.default_max_wait_time)
    fill_in "Prefix", with: "ACME"
    select "Acme Corp", from: "Organization"
    fill_in "Comment", with: "Reserving the acme prefix for Acme Corp"
    click_on "Save"

    page.assert_text "must be all lowercase"

    assert_empty PrefixReservation.all
  end
end
