require "application_system_test_case"

class Avo::EventsSystemTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

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
    @ip_address = create(:ip_address, ip_address: "127.0.0.1")
    stub_github_info_request(user.info_data)

    visit avo.root_path
    click_button "Log in with GitHub"

    page.assert_text user.login
  end

  test "user events" do
    sign_in_as(create(:admin_github_user, :is_admin))

    visit avo.root_path
    click_link "Events user events"

    assert_selector "div[data-target='title']", text: "Events user events"

    event = create(:events_user_event)
    refresh

    assert_content event.tag

    click_link href: avo.resources_events_user_event_path(event)

    assert_content event.tag
    assert_content event.cache_key
  end

  test "rubygem events" do
    sign_in_as(create(:admin_github_user, :is_admin))

    visit avo.root_path
    click_link "Events rubygem events"

    assert_selector "div[data-target='title']", text: "Events rubygem events"

    event = create(:events_rubygem_event)
    refresh

    assert_content event.tag

    click_link href: avo.resources_events_rubygem_event_path(event)

    assert_content event.tag
    assert_content event.cache_key
  end
end
