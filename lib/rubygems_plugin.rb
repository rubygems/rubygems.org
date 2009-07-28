$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

require 'rubygems/command_manager'

require 'commands/push'
require 'commands/tumble'

Gem::CommandManager.instance.register_command :push
Gem::CommandManager.instance.register_command :tumble

URL = "http://gemcutter.org" unless defined?(URL)
