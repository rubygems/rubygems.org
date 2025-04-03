# frozen_string_literal: true

require "test_helper"

class Maintenance::PolicyAnnouncementEmailTaskTest < ActiveSupport::TestCase
  test "send email to user" do
    user = create(:user)
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      Maintenance::PolicyAnnouncementEmailTask.process(user)
    end

    assert_equal [user.email], ActionMailer::Base.deliveries.last.to
  end
end
