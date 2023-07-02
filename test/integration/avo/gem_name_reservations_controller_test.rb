require "test_helper"

class Avo::GemNameReservationsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting gem_downloads as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    create(:gem_name_reservation, name: "hello")

    get avo.resources_gem_name_reservations_path

    assert_response :success

    # test resource search_query scope
    get avo.avo_api_search_path(q: "hello")

    assert_response :success
  end
end
