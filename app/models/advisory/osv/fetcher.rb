# frozen_string_literal: true

class Advisory::OSV::Fetcher < Advisory::Fetcher
  BASE_URL = "https://osv-vulnerabilities.storage.googleapis.com/RubyGems"
  DUMP_URL = "#{BASE_URL}/all.zip".freeze
  MAX_ENTRY_BYTES = 1.megabyte

  def self.advisory_class = Advisory::OSV

  def fetch
    documents_from_zip(download(DUMP_URL))
  end

  def map(document)
    Advisory::OSV::Mapper.call(document)
  end

  private

  def documents_from_zip(bytes)
    documents = []
    Zip::File.open_buffer(bytes.b) do |zip|
      zip.each do |entry|
        next unless json_entry?(entry)

        documents << parse_entry(entry)
      end
    end
    documents
  rescue Zip::Error => e
    raise Error, "Invalid OSV dump archive: #{e.message}"
  end

  def json_entry?(entry)
    entry.file? && entry.name.end_with?(".json") && entry.name.exclude?("/")
  end

  def parse_entry(entry)
    raise Error, "OSV dump entry too large: #{entry.name}" if entry.size > MAX_ENTRY_BYTES

    parse_json(entry.get_input_stream.read, entry.name)
  end

  def parse_json(raw, name)
    JSON.parse(raw)
  rescue JSON::ParserError => e
    raise Error, "Invalid OSV document #{name}: #{e.message}"
  end
end
