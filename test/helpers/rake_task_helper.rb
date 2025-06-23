require "rake"

# Run Rake tasks without loading them and introducing constant redefinition warnings
module RakeTaskHelper
  def setup_rake_tasks(task_file)
    Rake::Task.clear
    # :environment is already loaded when running tests, so stub it
    Rake::Task.define_task(:environment)
    load Rails.root.join("lib", "tasks", task_file)
  end
end
