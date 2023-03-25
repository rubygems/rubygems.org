require "test_helper"

class Avo::LogTicketsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting log_tickets as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_log_tickets_path

    assert_response :success

    log_ticket = create(:log_ticket)

    get avo.resources_log_tickets_path

    assert_response :success
    page.assert_text log_ticket.key

    get avo.resources_log_ticket_path(log_ticket)

    assert_response :success
    page.assert_text log_ticket.key
  end
end
