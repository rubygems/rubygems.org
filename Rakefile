require File.expand_path("config/application", __dir__)
Gemcutter::Application.load_tasks

# TODO: remove this when we point back to a release version of Avo
namespace :assets do
  task precompile: "avo:build-assets"
end
