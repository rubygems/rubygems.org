Rails.application.configure do
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = false
  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception) }
  config.good_job.queues = '*'
  config.good_job.shutdown_timeout = 25 # seconds

  GoodJob.active_record_parent_class = "ApplicationRecord"
end
