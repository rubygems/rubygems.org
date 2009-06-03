class Gem::Commands::DowngradeCommand < Gem::Command
  def description
    'Return to using RubyForge as your primary gem source'
  end

  def initialize
    super 'downgrade', description
  end

  def execute
    say "Your primary gem source is now gems.rubyforge.org"
    Gem.sources.delete URL
    Gem.configuration.write
  end
end

Gem::CommandManager.instance.register_command :downgrade
