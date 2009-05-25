class Gem::Commands::DowngradeCommand < Gem::Command
  DESCRIPTION = 'Return to using RubyForge as your primary gem source'

  def description
    DESCRIPTION
  end

  def initialize
    super 'downgrade', DESCRIPTION
  end

  def execute
    say "Your primary gem source is now gems.rubyforge.org"
    Gem.sources.delete "http://gems.gemcutter.org"
    Gem.sources << "http://gems.rubyforge.org"
    Gem.configuration.write
  end
end

Gem::CommandManager.instance.register_command :downgrade
