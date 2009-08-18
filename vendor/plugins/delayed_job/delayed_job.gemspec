# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{delayed_job}
  s.version = "1.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tobias L\303\274tke"]
  s.date = %q{2009-07-19}
  s.description = %q{Delayed_job (or DJ) encapsulates the common pattern of asynchronously executing longer tasks in the background. It is a direct extraction from Shopify where the job table is responsible for a multitude of core tasks.}
  s.email = %q{tobi@leetsoft.com}
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = [
    ".gitignore",
     "MIT-LICENSE",
     "README.textile",
     "Rakefile",
     "VERSION",
     "delayed_job.gemspec",
     "generators/delayed_job/delayed_job_generator.rb",
     "generators/delayed_job/templates/migration.rb",
     "generators/delayed_job/templates/script",
     "init.rb",
     "lib/delayed/command.rb",
     "lib/delayed/job.rb",
     "lib/delayed/message_sending.rb",
     "lib/delayed/performable_method.rb",
     "lib/delayed/worker.rb",
     "lib/delayed_job.rb",
     "recipes/delayed_job.rb",
     "spec/database.rb",
     "spec/delayed_method_spec.rb",
     "spec/job_spec.rb",
     "spec/story_spec.rb",
     "tasks/jobs.rake",
     "tasks/tasks.rb"
  ]
  s.homepage = %q{http://github.com/tobi/delayed_job/tree/master}
  s.rdoc_options = ["--main", "README.textile", "--inline-source", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Database-backed asynchronous priority queue system -- Extracted from Shopify}
  s.test_files = [
    "spec/database.rb",
     "spec/delayed_method_spec.rb",
     "spec/job_spec.rb",
     "spec/story_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
