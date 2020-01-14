module Lograge
  module Formatters
    class Datadog
      include Lograge::Formatters::Helpers::MethodAndPath

      def call(data)
        data.delete(:path)
        {
          timestamp: ::Time.now.utc,
          env: Rails.env,
          message: "[#{data[:status]}]#{method_and_path_string(data)}(#{data[:controller]}##{data[:action]})",
          http: {
            request_id: data.delete(:request_id),
            method: data.delete(:method),
            status_code: data.delete(:status),
            response_time_ms: data.delete(:duration),
            useragent: data.delete(:user_agent),
            url: data.delete(:url)
          },
          rails: {
            controller: data.delete(:controller),
            action: data.delete(:action),
            params: data.delete(:params),
            format: data.delete(:format),
            view_time_ms: data.delete(:view),
            db_time_ms: data.delete(:db)
          }.compact,
          network: {
            client: {
              ip: data.delete(:client_ip)
            }
          }
        }.merge(data).to_json
      end
    end
  end
end
