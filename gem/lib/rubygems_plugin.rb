require 'rubygems/command_manager'

if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.3.6')
  %w[migrate tumble webhook yank].each do |command|
    Gem::CommandManager.instance.register_command command.to_sym
  end
end
