desc "Format code with RuboCop and Prettier"
task format: %i[format:ruby format:js]

namespace :format do
  begin
    require "rubocop/rake_task"
  rescue LoadError # rubocop:disable Lint/SuppressedException
    task :ruby do
      puts "RuboCop is not available"
    end
  else
    Rake::Task[:ruby].clear if Rake::Task.task_defined?(:ruby)
    desc "Format Ruby code with RuboCop"
    RuboCop::RakeTask.new(:ruby) do |task|
      task.options = ["--display-cop-names", "--display-style-guide", "--fix-layout"]
      task.fail_on_error = true
    end
    task ruby: :environment
  end

  desc "Format JavaScript code with Prettier"
  task js: :environment do
    sh "bin/prettier --write 'app/javascript/**/*.js' 'config/*.js'"
  end
end
