# frozen_string_literal: true

class TransparencyLog::Tlog
  def initialize()
    @entry_builder = TransparencyLog::EntryBuilder.new
    @client = TransparencyLog::Client.new(ENV.fetch("TRANSPARENCY_LOG_REKOR_URL", "http://localhost:3004"))
  end

  def create_entry(transparency_log_event)
    entry = @entry_builder.build(transparency_log_event)
    response = @client.post(entry)
    TransparencyLogEvent::RekorResponse.new(
      response_body: response,
      rekor_entry: TransparencyLogEvent::RekorEntry.from_json(response)
    )
  rescue TransparencyLog::Client::Error => e
    Rails.logger.error(e.message)
    raise
  end
end
