# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['ENV']
dev_mode = ['', nil, 'development'].include? env

require 'bootsnap/setup' if dev_mode && !ENV['NO_BOOTSNAP']
