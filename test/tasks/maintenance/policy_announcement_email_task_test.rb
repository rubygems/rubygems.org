# frozen_string_literal: true

require "test_helper"

class Maintenance::PolicyAnnouncementEmailTaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
  end

  test "scoping the task to all users" do
    task = Maintenance::PolicyAnnouncementEmailTask.new

    assert_equal User.all, task.collection
  end

  test "places the background task in the correct queue" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob, queue: :within_24_hours) do
      Maintenance::PolicyAnnouncementEmailTask.process(@user)
    end
  end
end
