# frozen_string_literal: true

class Advisory::OSV::Fetcher < Advisory::Fetcher
  BASE_URL = "https://osv-vulnerabilities.storage.googleapis.com/RubyGems"
  DUMP_URL = "#{BASE_URL}/all.zip".freeze
  INDEX_URL = "#{BASE_URL}/modified_id.csv".freeze
  MAX_INCREMENTAL_IDS = 25
  MAX_ENTRY_BYTES = 1.megabyte

  def self.advisory_class = Advisory::OSV

  def fetch
    since = self.class.advisory_class.maximum(:modified_at)
    since ? fetch_updates(since) : fetch_all
  end

  def map(document)
    Advisory::OSV::Mapper.call(document)
  end

  private

  def fetch_all
    documents_from_zip(download(DUMP_URL))
  end

  def fetch_updates(since)
    ids = updated_ids(since)
    return fetch_all if ids.nil? || ids.size > MAX_INCREMENTAL_IDS

    incremental_documents(ids) || fetch_all
  end

  def updated_ids(since)
    ids = []
    CSV.parse(download(INDEX_URL)) do |modified, id, *|
      time = parse_modified(modified)
      next if time.blank? || id.blank?
      break if time < since
      next if ids.include?(id)

      ids << id
      break if ids.size > MAX_INCREMENTAL_IDS
    end
    ids
  rescue Faraday::Error => e
    log_incremental_fallback(e)
    nil
  end

  def incremental_documents(ids)
    ids.map { |id| JSON.parse(download(document_url(id))) }
  rescue Faraday::Error, JSON::ParserError => e
    log_incremental_fallback(e)
    nil
  end

  def document_url(id)
    "#{BASE_URL}/#{CGI.escapeURIComponent(id)}.json"
  end

  def documents_from_zip(bytes)
    documents = []
    Zip::File.open_buffer(bytes.b) do |zip|
      zip.each do |entry|
        next unless json_entry?(entry)

        documents << parse_entry(entry)
      end
    end
    documents.compact
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
  rescue JSON::ParserError
    Rails.logger.warn("Skipping invalid OSV document #{name}")
    nil
  end

  def parse_modified(value)
    Time.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def log_incremental_fallback(error)
    Rails.logger.warn("OSV incremental fetch failed (#{error.class}: #{error.message}); falling back to dump")
  end
end
