require 'test_helper'

class AnnouncementTest < ActiveSupport::TestCase
  context "token" do
    should "construct a unique token for each announcement" do
      announcement1 = Announcement.create(body: 'test')
      announcement2 = Announcement.create(body: 'test2', created_at: Date.yesterday)

      assert_not_equal announcement1.token, announcement2.token
    end
  end
end
