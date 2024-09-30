# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma starts a configurable number of processes (workers) and each process
# serves each request in a thread from an internal thread pool.
#
# The ideal number of threads per worker depends both on how much time the
# application spends waiting for IO operations and on how much you wish to
# to prioritize throughput over latency.
#
# As a rule of thumb, increasing the number of threads will increase how much
# traffic a given process can handle (throughput), but due to CRuby's
# Global VM Lock (GVL) it has diminishing returns and will degrade the
# response time (latency) of the application.
#
# The default is set to 3 threads as it's deemed a decent compromise between
# throughput and latency for the average Rails application.
#
# Any libraries that use a connection pool or another resource pool should
# be configured to provide at least as many connections as the number of
# threads. This includes Active Record's `pool` parameter in `database.yml`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

rails_env = ENV.fetch("RAILS_ENV") { "development" }
production_like = !%w[development test].include?(rails_env) # rubocop:disable Rails/NegateInclude

require "concurrent"

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

  # Run tailwindcss:watch in the background
  plugin :tailwindcss
end

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
environment rails_env

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

before_fork do
  sleep 1
end

on_worker_boot do
  # Re-open appenders after forking the process. https://logger.rocketjob.io/forking.html
  SemanticLogger.reopen
end

on_restart do
  Rails.configuration.launch_darkly_client&.close
end
