# frozen_string_literal: true

class ReorderVersionsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    perform_limit: 1,
    key: -> { "reorder-versions-#{arguments.first[:rubygem].id}" }
  )

  queue_as :default

  # If this job is discarded, latest/position may remain stale and Indexer/SetLinksetHomeJob will not run.
  # The full index can diverge from the compact index until a future version write enqueues another reorder.
  discard_on ActiveJob::DeserializationError

  def perform(rubygem:)
    logger.info { "Reordering versions for gem: #{rubygem.name} (#{rubygem.id})" }

    rubygem.transaction do
      StatsD.measure("reorder_versions.duration") do
        rubygem.reorder_versions
      end
    end
    StatsD.increment("reorder_versions.success")
    GemCachePurger.call(rubygem.name)
    Indexer.perform_later

    latest_version = rubygem.reload.most_recent_version
    SetLinksetHomeJob.perform_later(version: latest_version) if latest_version

    logger.info { "Reordering complete for #{rubygem.name}" }
  end
end
