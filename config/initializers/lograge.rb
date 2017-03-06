if Rails.env.production? || Rails.env.staging?
  Rails.application.configure do
    # Enable lograge
    config.lograge.enabled = true

    # Use (Logstash flavored) JSON
    config.lograge.formatter = Lograge::Formatters::Logstash.new

    # Keep the verbose logs for full debugging (locally)
    config.lograge.keep_original_rails_log = true

    # The new logs are shipped to the central logging
    config.lograge.logger = ActiveSupport::Logger.new Rails.root.join("log", "#{Rails.env}.json.log")

    # Add custom fields
    config.lograge.custom_options = lambda do |event|
      {
        params: event.payload[:params].except('controller', 'action', 'format', 'utf8'),
        client_ip: event.payload[:client_ip],
        user_agent: event.payload[:user_agent],
        dest_host: event.payload[:dest_host],
        request_id: event.payload[:request_id]
      }
    end
  end
end
