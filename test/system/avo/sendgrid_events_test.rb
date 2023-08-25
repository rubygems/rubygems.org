require "application_system_test_case"

class Avo::SendgridEventsSystemTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  def sign_in_as(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "1",
      credentials: {
        token: user.oauth_token,
        expires: false
      },
      info: {
        name: user.login
      }
    )
    stub_github_info_request(user.info_data)

    visit avo.root_path
    click_button "Log in with GitHub"

    page.assert_text user.login
  end

  test "search for event" do
    user = FactoryBot.create(:admin_github_user, :is_admin)
    sign_in_as(user)

    visit avo.resources_sendgrid_events_path

    event = FactoryBot.create(:sendgrid_event, email: "abcde@gmail.com")

    visit avo.resources_sendgrid_events_path

    page.assert_text event.email

    click_on "Filters"
    fill_in id: "avo_filters_email_filter", with: "nope"
    click_on "Filter by email"

    page.assert_no_text event.email
    page.assert_text "No record found"

    click_on "Filters"
    fill_in id: "avo_filters_email_filter", with: ".+e@gmail.*"
    click_on "Filter by email"

    page.assert_text event.email

    visit avo.resources_sendgrid_event_path(event)

    page.assert_text event.sendgrid_id
  end
end
