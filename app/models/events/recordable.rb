module Events::Recordable
  extend ActiveSupport::Concern

  def record_event!(tag, request: Current.request, **additional)
    ip_address = request&.ip_address
    geoip_info = ip_address&.geoip_info

    if (user_agent = request&.user_agent.presence)
      begin
        user_agent_info = Gemcutter::UserAgentParser.call(user_agent)
        additional[:user_agent_info] = user_agent_info
      rescue Gemcutter::UserAgentParser::UnableToParse => e
        Rails.error.report(e, context: { user_agent: }, handled: true)
      end
    end

    event = events.create!(tag:, ip_address:, geoip_info:, additional:, trace_id: Datadog::Tracing.correlation.trace_id)
    logger.info("Recorded event #{tag}", record: cache_key,
      event: event.as_json, tag:, ip_address: ip_address.as_json, additional: event.additional)
    event
  end

  included do
    has_many :events, class_name: "Events::#{name}Event", dependent: :destroy, inverse_of: model_name.param_key
  end
end
