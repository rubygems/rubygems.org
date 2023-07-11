Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = false
  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception, handled: false) }
  config.good_job.queues = '*'
  config.good_job.shutdown_timeout = 25 # seconds
  config.good_job.logger = SemanticLogger[GoodJob]

  config.good_job.enable_cron = !Rails.env.development?
  config.good_job.cron = {
    good_job_statsd: {
      cron: "every 15s",
      class: "GoodJobStatsDJob",
      set: { priority: 10 },
      description: "Sending GoodJob metrics to statsd every 15s"
    },
    mfa_usage_stats: {
      cron: "every hour",
      class: "MfaUsageStatsJob",
      set: { priority: 10 },
      description: "Sending MFA usage metrics to statsd every hour"
    }
  }

  # see https://github.com/bensheldon/good_job/pull/883
  # this makes good_job consistent with the priorities we used
  # previously for delayed job
  config.good_job.smaller_number_is_higher_priority = true

  GoodJob.active_record_parent_class = "ApplicationRecord"

  if Rails.env.development? && GoodJob::CLI.within_exe?
    GoodJob::CLI.log_to_stdout = false

    console = ActiveSupport::Logger.new($stdout)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

    Rails.logger.extend(ActiveSupport::Logger.broadcast(console)) unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, $stderr, $stdout)

    ActiveRecord::Base.logger = nil
    GoodJob.logger = Rails.logger
    StatsD.backend = StatsD::Instrument::Backends::NullBackend.new
  end
end
