class Gem::Commands::UpgradeCommand < Gem::Command
  def description
    'Upgrade your gem source to Gemcutter'
  end

  def initialize
    super 'upgrade', description
  end

  def execute
    say "Upgrading your primary gem source to gemcutter.org"
    Gem.sources.unshift "http://gemcutter.org"
    Gem.configuration.write
  end
end

Gem::CommandManager.instance.register_command :upgrade
