class Gem::Commands::MigrateCommand < Gem::Command
  def description
    'Migrate a gem your own from Rubyforge to Gemcutter.'
  end

  def initialize
    super 'migrate', description
  end

  def execute
  end
end
