# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

class TransparencyLog::Client
  class Error < StandardError; end
  class FormatError < Error; end

  attr_reader :rekor_url

  ENTRIES_PATH = "/api/v2/log/entries"

  def initialize
    @rekor_url = TransparencyLog.configuration.rekor_url
    @base_uri = URI.parse(@rekor_url)
    @http     = Net::HTTP.new(@base_uri.host, @base_uri.port)
    @http.use_ssl = @base_uri.scheme == "https"
  end

  def post(entry)
    response = @http.post(
      ENTRIES_PATH,
      JSON.dump(entry),
      headers
    )

    raise FormatError, "Malformed entry (400): #{response.body}" if response.code == "400"
    raise Error, "Request failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  private

  def headers
    {
      "Content-Type" => "application/json",
      "Accept"       => "application/json"
    }
  end
end
