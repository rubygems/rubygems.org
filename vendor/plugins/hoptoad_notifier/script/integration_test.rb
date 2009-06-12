#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), "..", "lib", "hoptoad_notifier")

fail "Please supply an API Key as the first argument" if ARGV.empty?

RAILS_ENV = "production"
RAILS_ROOT = "./"

host = ARGV[1]
host ||= "hoptoadapp.com"

secure = (ARGV[2] == "secure")

exception = begin
              raise "Testing hoptoad notifier with secure = #{secure}. If you can see this, it works."
            rescue => foo
              foo
            end

HoptoadNotifier.configure do |config|
  config.secure  = secure
  config.host    = host
  config.api_key = ARGV.first
end
puts "Sending #{secure ? "" : "in"}secure notification to project with key #{ARGV.first}"
HoptoadNotifier.notify(exception)

