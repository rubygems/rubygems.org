class FastlyLogProcessorJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:stats)

  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    # Maximum number of jobs with the concurrency key to be
    # concurrently performed (excludes enqueued jobs)
    #
    # Limited to avoid overloading the gem_download table with
    # too many concurrent conflicting updates
    perform_limit: good_job_concurrency_perform_limit(default: 5),
    key: name
  )

  def perform(bucket:, key:)
    FastlyLogProcessor.new(bucket, key).perform
  end
end
