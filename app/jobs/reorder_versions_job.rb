# frozen_string_literal: true

class ReorderVersionsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    total_limit: 1,
    key: -> { "reorder-versions-#{arguments.first[:rubygem].id}" }
  )

  queue_as :default

  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(rubygem:)
    logger.info { "Reordering versions for gem: #{rubygem.name} (#{rubygem.id})" }

    start_time = Time.zone.now
    rubygem.reorder_versions
    elapsed = ((Time.zone.now - start_time) * 1000).round(2)

    StatsD.increment("reorder_versions.success", tags: { gem: rubygem.name })
    StatsD.measure("reorder_versions.duration", elapsed, tags: { gem: rubygem.name })

    logger.info { "Reordering complete for #{rubygem.name} in #{elapsed}ms" }
  rescue StandardError => e
    logger.error { "Failed to reorder versions for #{rubygem.name}: #{e.message}" }
    StatsD.increment("reorder_versions.error", tags: { gem: rubygem.name, error: e.class.name })
    raise
  end
end
