# frozen_string_literal: true

class RebuildRubygemSearchJob < ApplicationJob
  queue_as :maintenance

  # Failure can happen after alias promotion. Inspect the index before retrying.
  retry_on StandardError, attempts: 1

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with total_limit: 1, key: name

  def perform
    logger.info "Starting full Rubygem search rebuild", job_id:
    Rubygem.reindex
    logger.info "Completed full Rubygem search rebuild", job_id:
  end
end
