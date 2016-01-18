require "rubocop"
require "rubocop/rake_task"

Rake::Task[:rubocop].clear if Rake::Task.task_defined?(:rubocop)
desc 'Execute rubocop'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--rails', '--display-cop-names', '--display-style-guide']
  task.fail_on_error = true
end
