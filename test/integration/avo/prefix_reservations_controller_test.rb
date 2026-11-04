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

  test "creating a prefix reservation that overlaps an existing one as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    other_organization = create(:organization)

    assert_no_difference [-> { PrefixReservation.count }, -> { Audit.count }] do
      post avo.resources_prefix_reservations_path, params: {
        prefix_reservation: { prefix: "acme-widgets", organization_id: other_organization.to_param, comment: "Reserving acme-widgets" }
      }
    end

    assert_response :unprocessable_content
    page.assert_text "overlaps the existing 'acme' reservation for the #{@organization.handle} organization"
  end

  test "creating and destroying a prefix reservation records who did each as admin" do
    admin = create(:admin_github_user, :is_admin)
    admin_sign_in_as admin

    post avo.resources_prefix_reservations_path, params: {
      prefix_reservation: { prefix: "widget", organization_id: @organization.to_param, comment: "Reserving widget for Acme Corp" }
    }
    prefix_reservation = PrefixReservation.find_by!(prefix: "widget")

    get avo.resources_associations_index_path(
      resource_name: "prefix_reservations",
      id: prefix_reservation.id,
      related_name: "audits"
    )

    assert_response :success
    page.assert_text "Manual create of PrefixReservation"

    delete avo.resources_prefix_reservation_path(prefix_reservation)

    refute PrefixReservation.exists?(prefix_reservation.id)
    audits = Audit.where(auditable_type: "PrefixReservation", auditable_id: prefix_reservation.id).order(:id)

    assert_equal ["Manual create of PrefixReservation", "Manual destroy of PrefixReservation"], audits.map(&:action)
    assert_equal [admin, admin], audits.map(&:admin_github_user)
    assert_equal "Reserving widget for Acme Corp", audits.first.comment
  end

  test "not creating a prefix reservation as an admin outside the rubygems.org team" do
    requires_avo_pro

    admin_sign_in_as admin_outside_rubygems_org_team

    get avo.new_resources_prefix_reservation_path

    assert_redirected_to avo.root_path

    assert_no_difference [-> { PrefixReservation.count }, -> { Audit.count }] do
      post avo.resources_prefix_reservations_path, params: {
        prefix_reservation: { prefix: "widget", organization_id: @organization.to_param, comment: "Reserving widget without permission" }
      }
    end

    assert_redirected_to avo.root_path
    refute PrefixReservation.exists?(prefix: "widget")
  end

  test "not destroying a prefix reservation as an admin outside the rubygems.org team" do
    requires_avo_pro

    admin_sign_in_as admin_outside_rubygems_org_team
    attributes = @prefix_reservation.reload.attributes

    assert_no_difference [-> { PrefixReservation.count }, -> { Audit.count }] do
      delete avo.resources_prefix_reservation_path(@prefix_reservation)
    end

    assert_redirected_to avo.root_path
    assert_equal attributes, PrefixReservation.find(@prefix_reservation.id).attributes
  end

  test "resource search_query scope" do
    requires_avo_pro

    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.avo_api_search_path(q: "acme")

    assert_response :success
  end

  private

  def admin_outside_rubygems_org_team
    admin = create(:admin_github_user, :is_admin)
    info_data = admin.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    admin.update!(info_data:)
    admin
  end
end
