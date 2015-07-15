if %(development test).include?(Rails.env)
  require 'rubocop/rake_task'

  desc 'Execute rubocop -DR'
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.options = ['-RDS'] # Rails, display cop name and styleguide link
  end
end
