# frozen_string_literal: true

require "rake"

# Run Rake tasks without loading them and introducing constant redefinition warnings
module RakeTaskHelper
  def setup_rake_tasks(*task_files)
    Rake::Task.clear
    # :environment is already loaded when running tests, so stub it
    Rake::Task.define_task(:environment)
    task_files.each do |task_file|
      load Rails.root.join("lib", "tasks", task_file)
    end
  end
end
