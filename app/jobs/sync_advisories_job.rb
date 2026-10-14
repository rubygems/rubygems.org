# frozen_string_literal: true

class SyncAdvisoriesJob < ApplicationJob
  queue_as "stats"

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  # Accept force for jobs enqueued before the advisory rollout flag was removed.
  def perform(source: nil, force: false) # rubocop:disable Lint/UnusedMethodArgument
    if source
      Advisory::Fetcher.sync(source)
    else
      Advisory::Fetcher.sync_all
    end
  end
end
