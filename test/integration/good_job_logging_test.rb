# frozen_string_literal: true

require "test_helper"

class GoodJobLoggingTest < ActiveSupport::TestCase
  class Job < ApplicationJob
    self.queue_adapter = ActiveJob::QueueAdapters::GoodJobAdapter.new(execution_mode: :external)

    def perform
    end
  end

  setup do
    # CI silences logs; these tests need to exercise the actual logging path.
    @original_log_level = ActiveJob::Base.logger.level
    ActiveJob::Base.logger.level = :info
    @logs = []
    @subscriber = ->(log) { @logs << log }
    SemanticLogger::Logger.subscribe(@subscriber)
    unless ActiveSupport::LogSubscriber.log_subscribers.any?(RailsSemanticLogger::ActiveJob::LogSubscriber)
      @job_log_subscriber = ActiveSupport::Notifications.subscribe(
        "enqueue.active_job", RailsSemanticLogger::ActiveJob::LogSubscriber.new
      )
    end
  end

  teardown do
    ActiveSupport::Notifications.unsubscribe(@job_log_subscriber) if @job_log_subscriber
    SemanticLogger::Logger.subscribers.delete(@subscriber)
    ActiveJob::Base.logger.level = @original_log_level
  end

  test "duplicate cron enqueues stay quiet without hiding the successful enqueue" do
    entry = GoodJob::CronEntry.new(key: "logging_test", cron: "every hour", class: Job.name)
    cron_at = Time.current.change(usec: 0)

    assert_difference "GoodJob::Job.where(cron_key: 'logging_test').count", 1 do
      assert entry.enqueue(cron_at)
      GoodJob::Job.transaction(requires_new: true) do
        refute entry.enqueue(cron_at)
        raise ActiveRecord::Rollback
      end
    end

    enqueue_logs = @logs.select { |log| log.metric == "rails.job.enqueue" }

    assert_equal [:info], enqueue_logs.map(&:level)
    assert_equal Job.name, enqueue_logs.first.payload[:job_class]
  end

  test "a different uniqueness violation still logs an enqueue error" do
    job = Job.perform_later

    error = assert_raises ActiveRecord::RecordNotUnique do
      GoodJob::Job.transaction(requires_new: true) { job.enqueue }
    end

    assert_equal "good_jobs_pkey", error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
    log = @logs.find { |event| event.metric == "rails.job.enqueue" && event.level == :error }

    assert log
    assert_same error, log.exception
    assert_equal 1, GoodJob::Job.where(active_job_id: job.job_id).count
  end

  test "a genuine enqueue failure still logs an error without persisting a job" do
    job = Job.new(Object.new)

    assert_no_difference "GoodJob::Job.count" do
      error = assert_raises(ActiveJob::SerializationError) { job.enqueue }

      log = @logs.find { |event| event.metric == "rails.job.enqueue" && event.level == :error }

      assert log
      assert_same error, log.exception
    end
  end
end
