require "net/http"

class Net::HTTP::Purge < Net::HTTPRequest
  METHOD = "PURGE".freeze
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = true
end

class Fastly
  # These are not kwargs because delayed_job doesn't correctly support kwargs in Fastly.delay.purge
  # See: https://github.com/collectiveidea/delayed_job/issues/1134
  def self.purge(options = {})
    return unless ENV["FASTLY_DOMAINS"].present? && ENV["FASTLY_API_KEY"].present?

    ENV["FASTLY_DOMAINS"].split(",").each do |domain|
      url = "https://#{domain}/#{options[:path]}"
      headers = options[:soft] ? { "Fastly-Soft-Purge" => 1 } : {}
      headers["Fastly-Key"] = ENV["FASTLY_API_KEY"]

      response = RestClient::Request.execute(method: :purge,
                                             url: url,
                                             timeout: 10,
                                             headers: headers)
      json = JSON.parse(response)
      Rails.logger.debug { "Fastly purge url=#{url} status=#{json['status']} id=#{json['id']}" }
    end
  end

  def self.purge_key(key, soft: false)
    return unless ENV["FASTLY_SERVICE_ID"].present? && ENV["FASTLY_API_KEY"].present?

    headers = { "Fastly-Key" => ENV["FASTLY_API_KEY"] }
    headers["Fastly-Soft-Purge"] = 1 if soft
    url = "https://api.fastly.com/service/#{ENV['FASTLY_SERVICE_ID']}/purge/#{key}"
    response = RestClient::Request.execute(method: :post,
                                           url: url,
                                           timeout: 10,
                                           headers: headers)
    json = JSON.parse(response)
    Rails.logger.debug { "Fastly purge url=#{url} status=#{json['status']} id=#{json['id']}" }
    json
  end
end
