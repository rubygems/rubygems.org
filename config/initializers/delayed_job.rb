require 'delayed_job'
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes

PRIORITIES = {push: 1, download: 2, web_hook: 3 }
