# frozen_string_literal: true

require "test_helper"

class Maintenance::PolicyReviewEndedEmailTaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
  end

  test "queues mail to be delivered to the user" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob, queue: :within_24_hours) do
      Maintenance::PolicyReviewEndedEmailTask.process(@user)
    end
  end
end
