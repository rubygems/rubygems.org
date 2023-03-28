# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
# max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
# min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
# threads min_threads_count, max_threads_count
threads 1, 1 # TODO: switch to threaded after initial puma deploy

require "concurrent"

rails_env = ENV.fetch("RAILS_ENV") { "development" }
production_like = %w[production staging].include?(rails_env)

if production_like
  # Specifies that the worker count should equal the number of processors in production.
  worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { Concurrent.physical_processor_count })
  workers worker_count if worker_count > 1
  worker_timeout 60
else
  # Specifies the `worker_timeout` threshold that Puma will use to wait before
  # terminating a worker in development environments.
  worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

  # Allow puma to be restarted by `bin/rails restart` command.
  plugin :tmp_restart
end

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
environment rails_env

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

before_fork do
  sleep 1
end

on_restart do
  Rails.configuration.launch_darkly_client&.close
end
