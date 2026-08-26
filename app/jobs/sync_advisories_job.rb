# frozen_string_literal: true

class SyncAdvisoriesJob < ApplicationJob
  queue_as "stats"

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  def perform(force: false)
    Advisory::Fetcher.sync_all(force:)
  end
end
