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

  context "when Rekor rejects the entry as malformed" do
    setup do
      @event = create(:transparency_log_event, status: :pending)
      @job   = ProcessTransparencyLogEventJob.new(@event)
      TransparencyLog::Tlog.any_instance.stubs(:create_entry)
        .raises(TransparencyLog::Client::FormatError.new("Malformed entry (400): Bad Request"))
    end

    should "mark the event as failed" do
      safely_perform(@job)
      assert_predicate @event.reload, :failed?
    end

    should "store the error message" do
      safely_perform(@job)
      assert_equal "Malformed entry (400): Bad Request", @event.reload.last_error
    end

    should "increment attempt_count" do
      safely_perform(@job)
      assert_equal 1, @event.reload.attempt_count
    end

    should "enqueue a retry for FormatError" do
      assert_enqueued_jobs 1, only: ProcessTransparencyLogEventJob do
        @job.perform_now
      end
    end
  end

  context "when Rekor accepts the submission" do
    setup do
      @event = create(:transparency_log_event, status: :pending)
      @job   = ProcessTransparencyLogEventJob.new(@event)
      rekor_entry = TransparencyLogEvent::RekorEntry.new(
        response_body: { "uuid" => "rekor-entry-uuid" },
        origin: "rekor.sigstore.dev",
        kind: "hashedrekord",
        version: "0.0.1",
        index: 123,
        checkpoint: "checkpoint",
        inclusion_proof: {}
      )
      TransparencyLog::Tlog.any_instance.stubs(:create_entry).returns(rekor_entry)
    end

    should "mark the event as submitted" do
      safely_perform(@job)
      assert_predicate @event.reload, :submitted?
    end

    should "persist the raw response body" do
      safely_perform(@job)
      assert_equal({ "uuid" => "rekor-entry-uuid" }, @event.reload.rekor_response_body)
    end

    should "persist the parsed rekor entry attributes" do
      safely_perform(@job)
      assert_equal "hashedrekord", @event.reload.rekor_entry_kind
    end
  end

  context "when Rekor accepts the submission but persisting it fails" do
    setup do
      @event = create(:transparency_log_event, status: :pending)
      @job   = ProcessTransparencyLogEventJob.new(@event)
      rekor_entry = TransparencyLogEvent::RekorEntry.new(
        response_body: { "uuid" => "rekor-entry-uuid" },
        origin: "rekor.sigstore.dev",
        kind: "hashedrekord",
        version: "0.0.1",
        index: 123,
        checkpoint: "checkpoint",
        inclusion_proof: {}
      )
      TransparencyLog::Tlog.any_instance.stubs(:create_entry).returns(rekor_entry)
      TransparencyLogEvent.any_instance.stubs(:record_submission).returns(false)
    end

    should "not raise" do
      assert_nothing_raised { @job.perform_now }
    end

    should "leave the event's status unchanged" do
      safely_perform(@job)
      assert_predicate @event.reload, :pending?
    end

    should "log an error" do
      Rails.logger.expects(:error).with(includes(@event.event_uuid.to_s))
      safely_perform(@job)
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
