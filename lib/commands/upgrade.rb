class Gem::Commands::UpgradeCommand < Gem::Command
  def description
    'Upgrade your gem source to Gemcutter'
  end

  def initialize
    super 'upgrade', description
  end

  def execute
    if Gem.sources.include?(URL)
      say "Gemcutter is already your primary gem source. Please use `gem downgrade` if you wish to no longer use Gemcutter."
    else
      Gem.sources.unshift URL
      Gem.configuration.write
      say "Your primary gem source is now gemcutter.org"
    end
  end
end
