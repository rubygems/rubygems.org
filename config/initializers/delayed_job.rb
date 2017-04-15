require 'delayed_job'
Delayed::Worker.max_attempts = 10
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.logger = Logger.new(Rails.root.join('log', 'delayed_job.log'))

PRIORITIES = { push: 1, download: 2, web_hook: 3, profile_deletion: 3, stats: 4 }.freeze
