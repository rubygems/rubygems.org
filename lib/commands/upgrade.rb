class Gem::Commands::UpgradeCommand < Gem::Command
  DESCRIPTION = 'Upgrade your gem source to Gemcutter'

  def description
    DESCRIPTION
  end

  def initialize
    super 'upgrade', DESCRIPTION
  end

  def execute
    say "Upgrading your primary gem source to gemcutter.org"

  end
end

Gem::CommandManager.instance.register_command :upgrade


