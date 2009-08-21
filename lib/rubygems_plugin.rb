$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

require 'rubygems/command_manager'
require 'commands/abstract_command'

%w[migrate owner push tumble].each do |command|
  require "commands/#{command}"
  Gem::CommandManager.instance.register_command command.to_sym
end

class GemCutter
  URL = "http://gemcutter.org" unless const_defined?(:URL)
end

class Gem::StreamUI
  def ask_for_password(message)
    system "stty -echo"
    password = ask(message)
    system "stty echo"
    password
  end
end
