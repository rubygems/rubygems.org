require 'test_helper'

class AnnouncementsHelperTest < ActionView::TestCase
  include AnnouncementsHelper

  context "announcement_visible?" do
    should "return true if user has not hidden the announcement" do
      announcement = Announcement.create(body: 'test')
      assert announcement_visible?(announcement)
    end

    should "return false if the user has hidden the current announcement" do
      announcement = Announcement.create(body: 'test')
      cookies[announcement.token] = 'hidden'
      refute announcement_visible?(announcement)
    end
  end

  context "current_announcement" do
    should "return the most recent announcement" do
      Announcement.create(body: 'test1')
      announcement2 = Announcement.create(body: 'test2')

      assert_equal current_announcement, announcement2
    end
  end
end
