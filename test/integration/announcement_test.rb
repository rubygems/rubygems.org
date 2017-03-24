require 'test_helper'

class AnnouncmentsTest < ActionDispatch::IntegrationTest
  test "user sees the latest announcement" do
    announcement = Announcement.create(body: 'Hello World')
    get root_path
    assert page.has_content?(announcement.body)
  end

  test "doesn't show the announcement after the user has hidden it" do
    announcement = Announcement.create(body: 'Hello World')
    cookies[announcement.token] = 'hidden'
    get root_path
    refute page.has_content?(announcement.body)
  end
end
