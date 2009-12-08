class Gem::Commands::TumbleCommand < Gem::AbstractCommand
  def initialize
    super 'tumble', description
  end

  def execute
    say "This command is deprecated, Gemcutter.org is the primary source for gems."
  end
end
