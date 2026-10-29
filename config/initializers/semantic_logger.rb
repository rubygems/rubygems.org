# frozen_string_literal: true

SemanticLogger.application = "rubygems.org"

Rails.application.config.after_initialize do
  # GoodJob rescues cron deduplication after Active Job has already logged it.
  Rails.logger.filter = lambda do |log|
    next true unless log.metric == "rails.job.enqueue" &&
      log.payload&.dig(:adapter) == "GoodJob" &&
      log.exception.is_a?(ActiveRecord::RecordNotUnique)

    cause = log.exception.cause
    !(cause.is_a?(PG::UniqueViolation) &&
      cause.result&.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME) == "index_good_jobs_on_cron_key_and_cron_at_cond")
  end

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
