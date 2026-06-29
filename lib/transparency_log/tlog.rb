# frozen_string_literal: true

class TransparencyLog::Tlog
  def initialize
    @entry_builder = TransparencyLog::EntryBuilder.new
    @client = TransparencyLog::Client.new(ENV.fetch("TRANSPARENCY_LOG_REKOR_URL"))
  end

  def create_entry(transparency_log_event)
    entry = @entry_builder.build(transparency_log_event)
    @client.post(entry)
  end
end
