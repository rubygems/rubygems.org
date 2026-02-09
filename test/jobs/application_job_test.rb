require "test_helper"

class ApplicationJobTest < ActiveSupport::TestCase
  class TestDiscardableJob < ApplicationJob
    discard_on ArgumentError

    def perform(should_raise: false)
      raise ArgumentError, "Test error" if should_raise
    end
  end

  test "after_discard callback reports metrics to StatsD" do
    job = TestDiscardableJob.new(should_raise: true)

    # allow reporting performance measurements
    StatsD.stubs(:increment)

    StatsD.expects(:increment).with(
      "good_job.discarded",
      tags: {
        queue: "default",
        priority: nil,
        job_class: "ApplicationJobTest::TestDiscardableJob",
        exception: "ArgumentError",
        adapter: "ActiveJob::QueueAdapters::TestAdapter"
      }
    ).once

    job.perform_now
  end
end
