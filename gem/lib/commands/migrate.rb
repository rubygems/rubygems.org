class Gem::Commands::MigrateCommand < Gem::AbstractCommand
  def description
    'Deprecate method for migrating a gem you own from Rubyforge to Gemcutter.'
  end

  def initialize
    super 'migrate', description
  end

  def execute
    say "This command is deprecated, RubyForge accounts/ownerships have been transferred to Gemcutter."
    say "Please see http://gemcutter.org/pages/migrate for more information"
  end
end
