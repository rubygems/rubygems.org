if Rails.env.production? || Rails.env.staging?
  require_relative "../../lib/lograge/formatters/datadog"

  Rails.application.configure do
    # Enable lograge
    config.lograge.enabled = true

    # Use (Datadog flavored) JSON
    config.lograge.formatter = Lograge::Formatters::Datadog.new

    # Add custom fields
    config.lograge.custom_payload do |controller|
      {
        url: controller.request.url,
        params: controller.request.filtered_parameters.except('controller', 'action', 'format', 'utf8'),
        client_ip: controller.request.ip,
        user_agent: controller.request.user_agent,
        request_id: controller.request.uuid
      }
    end
  end
end
