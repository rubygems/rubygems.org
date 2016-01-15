require 'delayed_job'
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.logger = Logger.new(Rails.root.join('log/delayed_job.log'))

PRIORITIES = { push: 1, download: 2, web_hook: 3, download_metrics: 4 }.freeze
