require "test_helper"

class ProcessSendgridEventJobTest < ActiveJob::TestCase
  test "calls #process" do
    SendgridEvent.any_instance.expects(:process)

    ProcessSendgridEventJob.perform_now(sendgrid_event: create(:sendgrid_event))
  end
end
