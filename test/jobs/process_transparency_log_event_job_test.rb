# frozen_string_literal: true

require "test_helper"

class ProcessTransparencyLogEventJobTest < ActiveJob::TestCase
  context "when the event is not pending" do
    setup do
      @event = create(:transparency_log_event, :submitted)
      @job   = ProcessTransparencyLogEventJob.new(@event)
    end

    should "leave the event's status unchanged" do
      safely_perform(@job)

      assert_predicate @event.reload, :submitted?
    end
  end

  context "when Rekor is unreachable" do
    setup do
      @event = create(:transparency_log_event, status: :pending)
      @job   = ProcessTransparencyLogEventJob.new(@event)
      TransparencyLog::Tlog.any_instance.stubs(:create_entry)
        .raises(TransparencyLog::Client::Error.new("timeout"))
    end

    should "mark the event as failed" do
      safely_perform(@job)

      assert_predicate @event.reload, :failed?
    end

    should "store the error message" do
      safely_perform(@job)

      assert_equal "timeout", @event.reload.last_error
    end

    should "increment attempt_count" do
      safely_perform(@job)

      assert_equal 1, @event.reload.attempt_count
    end
  end

  context "when an unexpected error is raised" do
    setup do
      @event = create(:transparency_log_event, status: :pending)
      @job   = ProcessTransparencyLogEventJob.new(@event)
      TransparencyLog::Tlog.any_instance.stubs(:create_entry)
        .raises(StandardError, "unexpected")
    end

    should "not mark the event as failed" do
      safely_perform(@job)

      assert_predicate @event.reload, :pending?
    end

    should "not store an error message" do
      safely_perform(@job)

      assert_nil @event.reload.last_error
    end
  end

  private

  def safely_perform(job)
    job.perform_now
  rescue Exception # rubocop:disable Lint/RescueException
    nil
  end
end