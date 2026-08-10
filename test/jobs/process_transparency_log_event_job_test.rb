# frozen_string_literal: true

require "test_helper"

class ProcessTransparencyLogEventJobTest < ActiveJob::TestCase
  context "when the event is not pending" do
    setup do
      @event = create(:transparency_log_event, :submitted)
      @job = ProcessTransparencyLogEventJob.new(@event)
    end

    should "leave the event status unchanged" do
      TransparencyLog::Tlog.any_instance.expects(:submit_entry).never

      safely_perform(@job)

      assert_predicate @event.reload, :submitted?
    end

    should "not enqueue a retry" do
      TransparencyLog::Tlog.any_instance.expects(:submit_entry).never

      assert_no_enqueued_jobs { safely_perform(@job) }
    end
  end

  context "when Rekor is unreachable" do
    setup do
      @event = create(:transparency_log_event, :request_built)
      @job = ProcessTransparencyLogEventJob.new(@event)
      TransparencyLog::Tlog.any_instance.stubs(:submit_entry).raises(TransparencyLog::Tlog::Error, "timeout")
    end

    should "mark the event as failed" do
      safely_perform(@job)

      assert_predicate @event.reload, :failed?
    end

    should "store the error message" do
      safely_perform(@job)

      assert_equal "timeout", @event.reload.last_error
    end

    should "increment attempt count" do
      safely_perform(@job)

      assert_equal 1, @event.reload.attempt_count
    end

    should "enqueue a retry" do
      assert_enqueued_jobs 1, only: ProcessTransparencyLogEventJob do
        safely_perform(@job)
      end
    end

    should "preserve the failed state before retrying" do
      safely_perform(@job)

      @event.reload

      assert_predicate @event, :failed?
      assert_equal 1, @event.attempt_count
      assert_equal "timeout", @event.last_error
    end
  end

  context "when Rekor rejects the entry as malformed" do
    setup do
      @event = create(:transparency_log_event, :request_built)
      @job = ProcessTransparencyLogEventJob.new(@event)
      TransparencyLog::Tlog.any_instance.stubs(:submit_entry)
        .raises(TransparencyLog::Tlog::FormatError, "Malformed entry (400): Bad Request")
    end

    should "mark the event as failed" do
      safely_perform(@job)

      assert_predicate @event.reload, :failed?
    end

    should "store the error message" do
      safely_perform(@job)

      assert_equal "Malformed entry (400): Bad Request", @event.reload.last_error
    end

    should "increment attempt count" do
      safely_perform(@job)

      assert_equal 1, @event.reload.attempt_count
    end

    should "enqueue a retry for FormatError" do
      assert_enqueued_jobs 1, only: ProcessTransparencyLogEventJob do
        safely_perform(@job)
      end
    end
  end

  context "when Rekor accepts the submission" do
    setup do
      @event = create(:transparency_log_event, :request_built)
      @job = ProcessTransparencyLogEventJob.new(@event)
    end

    should "submit the event through Tlog" do
      TransparencyLog::Tlog.any_instance.expects(:submit_entry).with(@event).once

      @job.perform_now
    end

    should "not enqueue a retry" do
      TransparencyLog::Tlog.any_instance.stubs(:submit_entry)

      assert_no_enqueued_jobs { @job.perform_now }
    end
  end

  context "when an unexpected error is raised" do
    setup do
      @event = create(:transparency_log_event, :request_built)
      @job = ProcessTransparencyLogEventJob.new(@event)
      TransparencyLog::Tlog.any_instance.stubs(:submit_entry).raises(StandardError, "unexpected")
    end

    should "not mark the event as failed" do
      safely_perform(@job)

      assert_predicate @event.reload, :pending?
    end

    should "not store an error message" do
      safely_perform(@job)

      assert_nil @event.reload.last_error
    end

    should "not increment attempt count" do
      safely_perform(@job)

      assert_equal 0, @event.reload.attempt_count
    end
  end

  private

  def safely_perform(job)
    job.perform_now
  rescue Exception # rubocop:disable Lint/RescueException
    nil
  end
end
