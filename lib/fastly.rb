class Fastly
  concerning :TraceTagging do
    class_methods do
      include TraceTagger
    end
  end

  include SemanticLogger::Loggable

  # These are not kwargs because delayed_job doesn't correctly support kwargs in Fastly.delay.purge
  # See: https://github.com/collectiveidea/delayed_job/issues/1134
  def self.purge(options = {})
    return unless ENV["FASTLY_DOMAINS"].present? && ENV["FASTLY_API_KEY"].present?

    ENV["FASTLY_DOMAINS"].split(",").each do |domain|
      url = "https://#{domain}/#{options[:path]}"
      trace("gemcutter.fastly.purge", resource: url,
            tags: { "gemcutter.fastly.domain" => domain, "gemcutter.fastly.path" => options[:path], "gemcutter.fastly.soft" => options[:soft] }) do
        headers = options[:soft] ? { "Fastly-Soft-Purge" => 1 } : {}
        headers["Fastly-Key"] = ENV["FASTLY_API_KEY"]

        response = RestClient::Request.execute(method: :purge,
                                              url: url,
                                              timeout: 10,
                                              headers: headers)
        json = JSON.parse(response)
        logger.debug { { message: "Fastly purge", url:, status: json["status"], id: json["id"] } }
      end
    end
  end

  def self.purge_key(key, soft: false)
    service_id = ENV["FASTLY_SERVICE_ID"]
    return unless service_id.present? && ENV["FASTLY_API_KEY"].present?

    trace("gemcutter.fastly.purge_key", resource: key, tags: { "gemcutter.fastly.service_id" => service_id, "gemcutter.fastly.soft" => soft }) do
      headers = { "Fastly-Key" => ENV["FASTLY_API_KEY"] }
      headers["Fastly-Soft-Purge"] = 1 if soft
      url = "https://api.fastly.com/service/#{service_id}/purge/#{key}"
      response = RestClient::Request.execute(method: :post,
                                            url: url,
                                            timeout: 10,
                                            headers: headers)
      json = JSON.parse(response)
      logger.debug { { message: "Fastly purge", url:, status: json["status"], id: json["id"] } }
      json
    end
  end
end
