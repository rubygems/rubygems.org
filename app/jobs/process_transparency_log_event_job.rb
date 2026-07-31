# frozen_string_literal: true

class ProcessTransparencyLogEventJob < ApplicationJob
  queue_as :default

  retry_on TransparencyLog::Tlog::Error, attempts: 5, wait: :polynomially_longer
  retry_on TransparencyLog::Tlog::FormatError, attempts: 3, wait: :polynomially_longer

  def perform(transparency_log_event)
    return unless transparency_log_event.pending?

    TransparencyLog::Tlog.new.submit_entry(transparency_log_event)
  rescue TransparencyLog::Tlog::Error => e
    transparency_log_event.record_failure(e)
    raise
  end
end
