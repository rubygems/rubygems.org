# frozen_string_literal: true

class ReorderVersionsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    perform_limit: 1,
    key: -> { "reorder-versions-#{arguments.first[:rubygem].id}" }
  )

  queue_as :default

  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(rubygem:)
    logger.info { "Reordering versions for gem: #{rubygem.name} (#{rubygem.id})" }

    StatsD.measure("reorder_versions.duration") do
      rubygem.reorder_versions
    end
    StatsD.increment("reorder_versions.success")

    # SetLinksetHomeJob relies on the freshly-updated `latest`, so enqueue it here
    # (after reordering) rather than before.
    latest_version = rubygem.reload.most_recent_version
    SetLinksetHomeJob.perform_later(version: latest_version) if latest_version

    logger.info { "Reordering complete for #{rubygem.name}" }
  rescue StandardError => e
    logger.error { "Failed to reorder versions for #{rubygem.name}: #{e.message}" }
    StatsD.increment("reorder_versions.error", tags: { error: e.class.name })
    raise
  end
end
