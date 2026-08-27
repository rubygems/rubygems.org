# frozen_string_literal: true

class SyncAdvisoriesJob < ApplicationJob
  queue_as "stats"

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  def perform(source: nil, force: false)
    if source
      Advisory::Fetcher.sync(source, force:)
    else
      Advisory::Fetcher.sync_all
    end
  end
end
