# This file is used by Rack-based servers to start the application.

require "datadog/profiling/preload"

require_relative "config/environment"

run Gemcutter::Application
Gemcutter::Application.load_server
