# frozen_string_literal: true

SemanticLogger.application = "rubygems.org"

Rails.application.config.after_initialize do
  ActiveSupport.on_load(:action_controller) do
    include Gemcutter::RequestLogPayload
  end
end

class SemanticErrorSubscriber
  include SemanticLogger::Loggable

  def report(error, handled:, severity:, context:, source: nil)
    logger.send severity.to_s.sub(/ing$/, ''), { exception: error, handled:, context:, source: }
  end
end

Rails.error.subscribe(SemanticErrorSubscriber.new)
