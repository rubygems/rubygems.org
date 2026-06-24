# frozen_string_literal: true

require "net/http"
require "json"

class TransparencyLog::Client
  def initialize(url)
    @url = url
  end

  def post(entry)
    uri = URI("#{@url}/api/v1/log/entries")

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    req.body = JSON.generate(entry)

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
  end
end
