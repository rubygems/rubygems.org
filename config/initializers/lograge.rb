if Rails.env.production? || Rails.env.staging?
  Rails.application.configure do
    # Enable lograge
    config.lograge.enabled = true

    # Use (Logstash flavored) JSON
    config.lograge.formatter = Lograge::Formatters::Logstash.new

    # Add custom fields
    config.lograge.custom_payload do |controller|
      {
        params: controller.request.params.except('controller', 'action', 'format', 'utf8'),
        client_ip: controller.request.ip,
        user_agent: controller.request.user_agent,
        dest_host: controller.request.host,
        request_id: controller.request.uuid
      }
    end
  end
end
