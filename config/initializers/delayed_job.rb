silence_warnings do
  Delayed::Job.const_set('MAX_ATTEMPTS', 3)
  Delayed::Job.const_set('MAX_RUN_TIME', 5.minutes)
  Delayed::Job.destroy_failed_jobs = false
end
