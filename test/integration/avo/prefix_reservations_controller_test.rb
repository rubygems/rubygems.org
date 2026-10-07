# frozen_string_literal: true

require "test_helper"

class Avo::PrefixReservationsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  setup do
    @organization = create(:organization, name: "Acme Corp")
    @prefix_reservation = create(:prefix_reservation, organization: @organization, prefix: "acme")
  end

  test "getting prefix reservations as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_prefix_reservations_path

    assert_response :success
    page.assert_text "acme"
  end

  test "getting a prefix reservation as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_prefix_reservation_path(@prefix_reservation)

    assert_response :success
    page.assert_text "acme"
    page.assert_text "Acme Corp"
  end

  test "getting the new prefix reservation form as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.new_resources_prefix_reservation_path

    assert_response :success
  end

  test "listing an organization's prefix reservations as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_associations_index_path(
      resource_name: "organizations",
      id: @organization.handle,
      related_name: "prefix_reservations"
    )

    assert_response :success
    page.assert_text "acme"
  end

  test "resource search_query scope" do
    requires_avo_pro

    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.avo_api_search_path(q: "acme")

    assert_response :success
  end
end
