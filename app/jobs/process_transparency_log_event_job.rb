# frozen_string_literal: true

class ProcessTransparencyLogEventJob < ApplicationJob
  queue_as :default

  def perform(transparency_log_event)
    return unless transparency_log_event.pending?

    rekor_response = TransparencyLog::Tlog.new.create_entry(transparency_log_event)

    unless transparency_log_event.record_submission(
      response_body: rekor_response.response_body,
      rekor_entry: rekor_response.rekor_entry
    )
      Rails.logger.error(
        "Rekor accepted entry but failed to persist submission for " \
        "#{transparency_log_event.event_uuid}: " \
        "#{transparency_log_event.errors.full_messages.join(', ')}"
      )
    end
  rescue TransparencyLog::Client::Error => e
    transparency_log_event.record_failure(e)
    raise
  end
  # done
end