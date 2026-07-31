# frozen_string_literal: true

class TransparencyLog::Tlog
  class Error < StandardError; end
  class FormatError < Error; end

  def initialize
    @client = TransparencyLog::Client.new
  end

  def submit_entry(transparency_log_event)
    response = @client.post(transparency_log_event.rekor_request_body)
    rekor_response = TransparencyLogEvent::RekorResponse.from_json(response)

    unless transparency_log_event.record_submission(rekor_response)
      Rails.logger.error(
        "Rekor accepted entry but failed to persist submission for " \
        "#{transparency_log_event.event_uuid}: " \
        "#{transparency_log_event.errors.full_messages.join(', ')}"
      )
    end
  rescue TransparencyLog::Client::FormatError => e
    raise FormatError, e.message
  rescue TransparencyLog::Client::Error => e
    raise Error, e.message
  end
end
