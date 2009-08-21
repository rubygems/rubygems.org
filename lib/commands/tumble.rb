class Gem::Commands::TumbleCommand < Gem::AbstractCommand
  def description
    'Enable or disable Gemcutter as your primary gem source.'
  end

  def initialize
    super 'tumble', description
  end

  def execute
    say "Thanks for using Gemcutter!"
    tumble
    show_sources
  end

  def tumble
    if Gem.sources.include?(GemCutter::URL)
      Gem.sources.delete GemCutter::URL
      Gem.configuration.write
    else
      Gem.sources.unshift GemCutter::URL
      Gem.configuration.write
    end
  end

  def show_sources
    say "Your gem sources are now:"
    Gem.sources.each do |source|
      say "- #{source}"
    end
  end
end
