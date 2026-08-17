# frozen_string_literal: true

require "test_helper"

class Organizations::GemNameReservationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = create(:organization)
    @user = create(:user)
    @membership = create(:membership, organization: @organization, user: @user, role: :admin)

    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  test "GET /organizations/:organization_handle/reservations" do
    create(:gem_name_reservation, organization: @organization, name: "zeta-gem")
    create(:gem_name_reservation, organization: @organization, name: "alpha-gem")

    get organization_gem_name_reservations_path(@organization)

    assert_response :success
    assert_select "h1", text: "Reserved Names"
    assert_equal %w[alpha-gem zeta-gem], css_select("[data-testid=gem-name-reservation] p").map(&:text)
  end

  test "GET /organizations/:organization_handle/reservations as an owner" do
    @membership.update!(role: "owner")

    get organization_gem_name_reservations_path(@organization)

    assert_response :success
  end

  test "GET /organizations/:organization_handle/reservations as a maintainer" do
    @membership.update!(role: "maintainer")
    create(:gem_name_reservation, organization: @organization, name: "alpha-gem")

    get organization_gem_name_reservations_path(@organization)

    assert_response :success
    assert_equal ["alpha-gem"], css_select("[data-testid=gem-name-reservation] p").map(&:text)
  end

  test "GET /organizations/:organization_handle/reservations as a maintainer hides the reserve and remove buttons" do
    @membership.update!(role: "maintainer")
    create(:gem_name_reservation, organization: @organization, name: "alpha-gem")

    get organization_gem_name_reservations_path(@organization)

    assert_response :success
    assert_empty css_select("[data-testid=reserve-gem-name]")
    assert_empty css_select("[data-testid=remove-gem-name-reservation]")
  end

  test "GET /organizations/:organization_handle/reservations as an admin shows the reserve and remove buttons" do
    create(:gem_name_reservation, organization: @organization, name: "alpha-gem")

    get organization_gem_name_reservations_path(@organization)

    assert_response :success
    assert_equal 1, css_select("[data-testid=reserve-gem-name]").size
    assert_equal 1, css_select("[data-testid=remove-gem-name-reservation]").size
  end

  test "GET /organizations/:organization_handle/reservations as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get organization_gem_name_reservations_path(@organization)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/reservations when signed out" do
    delete sign_out_path

    get organization_gem_name_reservations_path(@organization)

    assert_redirected_to sign_in_path
  end

  test "GET /organizations/:organization_handle/reservations for an unknown organization" do
    get organization_gem_name_reservations_path("not-an-organization")

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/reservations with no reservations" do
    get organization_gem_name_reservations_path(@organization)

    assert_response :success
    assert page.has_content? "No reserved names yet"
  end

  test "GET /organizations/:organization_handle/reservations only lists this organization's reservations" do
    create(:gem_name_reservation, organization: @organization, name: "ours")
    create(:gem_name_reservation, organization: create(:organization), name: "theirs")
    create(:gem_name_reservation, name: "unowned")

    get organization_gem_name_reservations_path(@organization)

    assert_response :success
    assert_equal ["ours"], css_select("[data-testid=gem-name-reservation] p").map(&:text)
  end

  test "GET /organizations/:organization_handle/reservations paginates after 50" do
    names = Array.new(51) { |i| format("gem-%02d", i) }
    names.each { |name| create(:gem_name_reservation, organization: @organization, name: name) }

    get organization_gem_name_reservations_path(@organization)

    assert_response :success
    assert_equal names.first(50), css_select("[data-testid=gem-name-reservation] p").map(&:text)

    get organization_gem_name_reservations_path(@organization, page: 2)

    assert_response :success
    assert_equal names.last(1), css_select("[data-testid=gem-name-reservation] p").map(&:text)
  end

  test "GET /organizations/:organization_handle/reservations/new" do
    get new_organization_gem_name_reservation_path(@organization)

    assert_response :success
    assert_select "h3", text: "Reserve a Name"
  end

  test "GET /organizations/:organization_handle/reservations/new as a maintainer" do
    @membership.update!(role: "maintainer")

    get new_organization_gem_name_reservation_path(@organization)

    assert_response :not_found
  end

  test "GET /organizations/:organization_handle/reservations/new as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get new_organization_gem_name_reservation_path(@organization)

    assert_response :not_found
  end

  test "POST /organizations/:organization_handle/reservations" do
    post organization_gem_name_reservations_path(@organization), params: { gem_name_reservation: { name: "sandworm" } }

    assert_redirected_to organization_gem_name_reservations_path(@organization)
    assert_equal "Gem name reserved.", flash[:notice]
    assert_equal @organization, GemNameReservation.find_by!(name: "sandworm").organization
  end

  test "POST /organizations/:organization_handle/reservations as an owner" do
    @membership.update!(role: "owner")

    post organization_gem_name_reservations_path(@organization), params: { gem_name_reservation: { name: "sandworm" } }

    assert_redirected_to organization_gem_name_reservations_path(@organization)
    assert GemNameReservation.reserved?("sandworm")
  end

  test "POST /organizations/:organization_handle/reservations with an uppercase name" do
    post organization_gem_name_reservations_path(@organization), params: { gem_name_reservation: { name: "Sandworm" } }

    assert_response :unprocessable_content
    assert page.has_content? "Name must be all lowercase"
    assert_empty @organization.gem_name_reservations
  end

  test "POST /organizations/:organization_handle/reservations for an existing gem" do
    create(:rubygem, name: "sandworm")

    post organization_gem_name_reservations_path(@organization), params: { gem_name_reservation: { name: "sandworm" } }

    assert_response :unprocessable_content
    assert page.has_content? "Name rubygem exists with name"
    assert_empty @organization.gem_name_reservations
  end

  test "POST /organizations/:organization_handle/reservations for an already reserved name" do
    create(:gem_name_reservation, organization: create(:organization), name: "sandworm")

    post organization_gem_name_reservations_path(@organization), params: { gem_name_reservation: { name: "sandworm" } }

    assert_response :unprocessable_content
    assert_empty @organization.gem_name_reservations
  end

  test "POST /organizations/:organization_handle/reservations as a maintainer" do
    @membership.update!(role: "maintainer")

    post organization_gem_name_reservations_path(@organization), params: { gem_name_reservation: { name: "sandworm" } }

    assert_response :not_found
    refute GemNameReservation.reserved?("sandworm")
  end

  test "POST /organizations/:organization_handle/reservations as a guest" do
    guest = create(:user)
    post session_path(session: { who: guest.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    post organization_gem_name_reservations_path(@organization), params: { gem_name_reservation: { name: "sandworm" } }

    assert_response :not_found
    refute GemNameReservation.reserved?("sandworm")
  end

  test "DELETE /organizations/:organization_handle/reservations/:id" do
    reservation = create(:gem_name_reservation, organization: @organization, name: "sandworm")

    delete organization_gem_name_reservation_path(@organization, reservation)

    assert_redirected_to organization_gem_name_reservations_path(@organization)
    assert_equal "Gem name reservation removed.", flash[:notice]
    refute GemNameReservation.reserved?("sandworm")
  end

  test "DELETE /organizations/:organization_handle/reservations/:id as a maintainer" do
    @membership.update!(role: "maintainer")
    reservation = create(:gem_name_reservation, organization: @organization, name: "sandworm")

    delete organization_gem_name_reservation_path(@organization, reservation)

    assert_response :not_found
    assert GemNameReservation.reserved?("sandworm")
  end

  test "DELETE /organizations/:organization_handle/reservations/:id belonging to another organization" do
    reservation = create(:gem_name_reservation, organization: create(:organization), name: "sandworm")

    delete organization_gem_name_reservation_path(@organization, reservation)

    assert_response :not_found
    assert GemNameReservation.reserved?("sandworm")
  end

  test "DELETE /organizations/:organization_handle/reservations/:id not owned by any organization" do
    reservation = create(:gem_name_reservation, name: "sandworm")

    delete organization_gem_name_reservation_path(@organization, reservation)

    assert_response :not_found
    assert GemNameReservation.reserved?("sandworm")
  end
end
