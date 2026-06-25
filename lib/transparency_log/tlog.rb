# frozen_string_literal: true

class TransparencyLog::Tlog
  def initialize
    @entry_builder = TransparencyLog::EntryBuilder.new(OpenSSL::PKey::EC.generate("prime256v1"))
    @client = TransparencyLog::Client.new("http://localhost:3004")
  end

  def create_entry(json_payload)
    entry = @entry_builder.build(json_payload)
    @client.post(entry)
  end
end
