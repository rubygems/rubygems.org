# frozen_string_literal: true

class TransparencyLog::Tlog
  def initialize
    @entry_builder = TransparencyLog::EntryBuilder.new
    @client = TransparencyLog::Client.new(TransparencyLog.rekor_url)
  end

  def create_entry(transparency_log_event)
    entry = @entry_builder.build(transparency_log_event)
    response = @client.post(entry)
    TransparencyLogEvent::RekorEntry.from_json(response)
  rescue TransparencyLog::Client::FormatError => e
    Rails.logger.error("Transparency log entry malformed: #{e.message}")
    raise
  rescue TransparencyLog::Client::Error => e
    Rails.logger.error(e.message)
    raise
  end
end