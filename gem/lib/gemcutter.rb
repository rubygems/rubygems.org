require 'commands/abstract_command'

%w[migrate owner push tumble webhook].each do |command|
  require "commands/#{command}"
  Gem::CommandManager.instance.register_command command.to_sym
end
