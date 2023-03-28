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

    connection = make_connection

    ENV["FASTLY_DOMAINS"].split(",").each do |domain|
      url = "https://#{domain}/#{options[:path]}"
      trace("gemcutter.fastly.purge", resource: url,
            tags: { "gemcutter.fastly.domain" => domain, "gemcutter.fastly.path" => options[:path], "gemcutter.fastly.soft" => options[:soft] }) do
        headers = options[:soft] ? { "Fastly-Soft-Purge" => "1" } : {}
        headers["Fastly-Key"] = ENV["FASTLY_API_KEY"]

        json = connection.get(url, nil, headers) do |req|
          req.http_method = :purge
        end
        logger.debug { { message: "Fastly purge", url:, status: json["status"], id: json["id"] } }
      end
    end
  end

  def self.purge_key(key, soft: false)
    service_id = ENV["FASTLY_SERVICE_ID"]
    return unless service_id.present? && ENV["FASTLY_API_KEY"].present?

    trace("gemcutter.fastly.purge_key", resource: key, tags: { "gemcutter.fastly.service_id" => service_id, "gemcutter.fastly.soft" => soft }) do
      headers = { "Fastly-Key" => ENV["FASTLY_API_KEY"] }
      headers["Fastly-Soft-Purge"] = "1" if soft
      url = "https://api.fastly.com/service/#{service_id}/purge/#{key}"
      json = make_connection.post(url, nil, headers)
      logger.debug { { message: "Fastly purge", url:, status: json["status"], id: json["id"] } }
      json
    end
  end

  def self.make_connection
    Faraday.new(nil, request: { timeout: 10 }) do |f|
      f.request :json
      f.response :json
      f.response :logger, logger, headers: false, errors: true
      f.response :raise_error
    end
  end
end
