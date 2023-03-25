require "test_helper"

class GoodJobStatsDJobTest < ActiveSupport::TestCase
  include StatsD::Instrument::Assertions

  # opt-out default retries
  class FailureJob < ActiveJob::Base # rubocop:disable Rails/ApplicationJob
    self.queue_adapter = ActiveJob::QueueAdapters::GoodJobAdapter.new(execution_mode: :async)
    queue_as :fail_once
    def perform
      raise StandardError, "failure"
    end
  end

  class DiscardJob < ApplicationJob
    self.queue_adapter = ActiveJob::QueueAdapters::GoodJobAdapter.new(execution_mode: :async)
    discard_on StandardError
    def perform
      raise StandardError, "discard"
    end
  end

  class RetryJob < ApplicationJob
    self.queue_adapter = ActiveJob::QueueAdapters::GoodJobAdapter.new(execution_mode: :async)
    queue_as :retry_once
    retry_on StandardError
    def perform
      raise StandardError, "retry"
    end
  end

  class SuccessJob < ApplicationJob
    self.queue_adapter = ActiveJob::QueueAdapters::GoodJobAdapter.new(execution_mode: :async)
    def perform
    end
  end

  class ConcurrencyLimitedJob < ApplicationJob
    self.queue_adapter = ActiveJob::QueueAdapters::GoodJobAdapter.new(execution_mode: :async)
    queue_as :concurrency_limited
    include GoodJob::ActiveJobExtensions::Concurrency
    good_job_control_concurrency_with(
      perform_limit: 0,
      key: name
    )
    def perform
    end
  end

  def metric(**args)
    StatsD::Instrument::MetricExpectation.new(**args.reverse_merge(times: 1))
  end

  setup do
    GoodJobStatsDJob.disable_test_adapter
    GoodJobStatsDJob.stubs(:queue_adapter).returns(ActiveJob::QueueAdapters::GoodJobAdapter.new(execution_mode: :async))
  end

  test "reports metrics to statsd" do
    travel_to Time.utc(2023, 3, 6, 1, 2, 3)
    FailureJob.perform_later
    DiscardJob.perform_later
    RetryJob.perform_later
    SuccessJob.perform_later
    ConcurrencyLimitedJob.perform_later

    begin
      GoodJob.perform_inline("retry_once")
    rescue StandardError
      nil
    end
    begin
      GoodJob.perform_inline("fail_once")
    rescue StandardError
      nil
    end
    GoodJob.perform_inline

    3.times do
      travel 1.day
      GoodJob.perform_inline("concurrency_limited")
    end

    SuccessJob.set(priority: -2).perform_later

    assert_statsd_calls [
      metric(name: "rails.perform_start.active_job.total_duration", type: :ms,
             tags: { "queue" => "stats", "job_class" => "GoodJobStatsDJob",
                     "adapter" => "ActiveJob::QueueAdapters::GoodJobAdapter", "env" => "test" }),
      metric(name: "rails.perform_start.active_job.allocations", type: :h,
             tags: { "queue" => "stats", "job_class" => "GoodJobStatsDJob" }),
      metric(name: "rails.perform_start.active_job.success", type: :c,
             value: 1,
             tags: { "queue" => "stats", "job_class" => "GoodJobStatsDJob" }),

      # Retry job
      metric(name: "good_job.count", type: :g,
             value: 1,
             tags: { "state" => "queued", "queue" => "retry_once", "priority" => "0",
                     "job_class" => "GoodJobStatsDJobTest::RetryJob", "env" => "test" }),
      metric(name: "good_job.staleness", type: :g,
             tags: { "state" => "queued", "queue" => "retry_once", "priority" => "0",
                     "job_class" => "GoodJobStatsDJobTest::RetryJob", "env" => "test" }),

      # Concurrency limited job
      metric(name: "good_job.count", type: :g,
             value: 1,
              tags: { "state" => "retried", "queue" => "concurrency_limited", "priority" => "0",
                      "job_class" => "GoodJobStatsDJobTest::ConcurrencyLimitedJob", "env" => "test" }),
      metric(name: "good_job.staleness", type: :g,
          value: 3.days,
              tags: { "state" => "retried", "queue" => "concurrency_limited", "priority" => "0",
                      "job_class" => "GoodJobStatsDJobTest::ConcurrencyLimitedJob", "env" => "test" }),

      # Failure job
      metric(name: "good_job.count", type: :g,
             value: 1,
             tags: { "state" => "discarded", "queue" => "fail_once", "priority" => "0",
                     "job_class" => "GoodJobStatsDJobTest::FailureJob", "env" => "test" }),
      metric(name: "good_job.staleness", type: :g,
             tags: { "state" => "discarded", "queue" => "fail_once", "priority" => "0",
                     "job_class" => "GoodJobStatsDJobTest::FailureJob", "env" => "test" }),

      # Success job
      metric(name: "good_job.count", type: :g,
             value: 1,
             tags: { "state" => "queued", "queue" => "default", "priority" => "-2",
                     "job_class" => "GoodJobStatsDJobTest::SuccessJob", "env" => "test" }),
      metric(name: "good_job.count", type: :g,
             value: 1,
             tags: { "state" => "succeeded", "queue" => "default", "priority" => "0",
                     "job_class" => "GoodJobStatsDJobTest::SuccessJob", "env" => "test" }),
      metric(name: "good_job.staleness", type: :g,
             tags: { "state" => "queued", "queue" => "default", "priority" => "-2",
                     "job_class" => "GoodJobStatsDJobTest::SuccessJob", "env" => "test" }),
      metric(name: "good_job.staleness", type: :g,
             tags: { "state" => "succeeded", "queue" => "default", "priority" => "0",
                     "job_class" => "GoodJobStatsDJobTest::SuccessJob", "env" => "test" }),

      # Discard job
      metric(name: "good_job.count", type: :g,
             value: 1,
             tags: { "state" => "discarded", "queue" => "default", "priority" => "0",
                     "job_class" => "GoodJobStatsDJobTest::DiscardJob", "env" => "test" }),
      metric(name: "good_job.staleness", type: :g,
             tags: { "state" => "discarded", "queue" => "default", "priority" => "0",
                     "job_class" => "GoodJobStatsDJobTest::DiscardJob", "env" => "test" }),

      metric(name: "rails.perform.active_job.total_duration", type: :ms,
             tags: { "queue" => "stats", "job_class" => "GoodJobStatsDJob" }),
      metric(name: "rails.perform.active_job.allocations", type: :h,
             tags: { "queue" => "stats", "job_class" => "GoodJobStatsDJob" }),
      metric(name: "rails.perform.active_job.success", type: :c,
             value: 1,
             tags: { "queue" => "stats", "job_class" => "GoodJobStatsDJob" })
    ] do
      GoodJobStatsDJob.perform_now
    end
  end
end
