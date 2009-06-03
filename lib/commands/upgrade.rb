class Gem::Commands::UpgradeCommand < Gem::Command
  def description
    'Upgrade your gem source to Gemcutter'
  end

  def initialize
    super 'upgrade', description
  end

  def execute
    if Gem.sources.include?(URL)
      say("Gemcutter is already your primary gem source. Please use `gem downgrade` if you wish to no longer use Gemcutter.")
    else
      say "Upgrading your primary gem source to gemcutter.org"
      Gem.sources.unshift URL
      Gem.configuration.write
    end
  end
end

Gem::CommandManager.instance.register_command :upgrade
