# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

class TransparencyLog::Client
  ENTRIES_PATH = "/api/v2/log/entries"

  def initialize(url)
    @base_uri = URI.parse(url)
    @http     = Net::HTTP.new(@base_uri.host, @base_uri.port)
    @http.use_ssl = @base_uri.scheme == "https"
  end

  def post(entry)
    @http.post(
      ENTRIES_PATH,
      JSON.dump(entry),
      headers
    )
  end

  private

  def headers
    {
      "Content-Type" => "application/json",
      "Accept"       => "application/json"
    }
  end
end
