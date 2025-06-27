require "application_system_test_case"

class Avo::SendgridEventsSystemTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "search for event" do
    user = FactoryBot.create(:admin_github_user, :is_admin)
    avo_sign_in_as(user)

    visit avo.resources_sendgrid_events_path

    event = FactoryBot.create(:sendgrid_event, email: "abcde@gmail.com")

    visit avo.resources_sendgrid_events_path

    assert_text event.email

    click_on "Filters"
    fill_in id: "avo_filters_email_filter", with: "nope"
    click_on "Filter by email"

    assert_no_text event.email
    assert_text "No record found"

    click_on "Filters"
    fill_in id: "avo_filters_email_filter", with: ".+e@gmail.*"
    click_on "Filter by email"

    assert_text event.email

    visit avo.resources_sendgrid_event_path(event)

    assert_text event.sendgrid_id
  end
end
