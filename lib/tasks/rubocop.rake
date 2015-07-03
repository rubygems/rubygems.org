require 'rubocop/rake_task'

desc 'Execute rubocop -DR'
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['-DR'] # Rails, display cop name
end
