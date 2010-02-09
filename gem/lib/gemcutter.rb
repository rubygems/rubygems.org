require 'commands/gemcutter_utils'

%w[migrate owner push tumble webhook].each do |command|
  Gem::CommandManager.instance.register_command command.to_sym
end
