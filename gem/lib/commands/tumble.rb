class Gem::Commands::TumbleCommand < Gem::AbstractCommand
  def description
    "Deprecated method of upgrading to Gemcutter.org for gem downloads"
  end

  def initialize
    super 'tumble', description
  end

  def execute
    say "This command is deprecated, Gemcutter.org is the primary source for gems."
  end
end
