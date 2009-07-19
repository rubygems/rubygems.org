$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

require 'rubygems/command_manager'

require 'commands/downgrade'
require 'commands/push'
require 'commands/upgrade'

Gem::CommandManager.instance.register_command :downgrade
Gem::CommandManager.instance.register_command :push
Gem::CommandManager.instance.register_command :upgrade

URL = "http://gemcutter.org" unless defined?(URL)
