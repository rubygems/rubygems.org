$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

require 'rubygems/command_manager'
require 'commands/abstract_command'
require 'net/http'
require 'net/https'

%w[migrate owner push tumble].each do |command|
  require "commands/#{command}"
  Gem::CommandManager.instance.register_command command.to_sym
end
