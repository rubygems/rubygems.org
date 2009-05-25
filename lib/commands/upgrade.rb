class Gem::Commands::UpgradeCommand < Gem::Command
  DESCRIPTION = 'Upgrade your gem source to Gemcutter'

  def description
    DESCRIPTION
  end

  def initialize
    super 'upgrade', DESCRIPTION
  end

  def execute
    say "Upgrading your primary gem source to gems.gemcutter.org"
    Gem.sources.delete "http://gems.rubyforge.org"
    Gem.sources << "http://gems.gemcutter.org"
    Gem.configuration.write
  end
end

Gem::CommandManager.instance.register_command :upgrade
