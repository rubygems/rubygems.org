Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = false
  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception) }
  config.good_job.queues = '*'
  config.good_job.shutdown_timeout = 25 # seconds

  config.good_job.enable_cron = true
  config.good_job.cron = {
    good_job_statsd: {
      cron: "every 15s",
      class: "GoodJobStatsDJob",
      set: { priority: 10 },
      description: "Sending GoodJob metrics to statsd every 15s"
    }
  }

  GoodJob.active_record_parent_class = "ApplicationRecord"
end
