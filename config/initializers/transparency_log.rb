# frozen_string_literal: true

require_relative "../../lib/transparency_log"

TransparencyLog.configure do |c|
    c.rekor_url = ENV["TRANSPARENCY_LOG_REKOR_URL"] if ENV["TRANSPARENCY_LOG_REKOR_URL"].presence
end