Gem::Specification.new do |s|
  s.name = "limerick_rake"
  s.version = "0.0.2"
  s.date = "2008-10-07"
  s.summary = "A collection of useful rake tasks."
  s.email = "support@thoughtbot.com"
  s.homepage = "http://github.com/thoughtbot/limerick_rake"
  s.description = "A collection of useful rake tasks."
  s.authors = ["the Ruby community", "thoughtbot, inc."]
  s.files = ["README.textile",
    "limerick_rake.gemspec",
    "tasks/backup.rake",
    "tasks/db/bootstrap.rake",
    "tasks/db/indexes.rake",
    "tasks/db/shell.rake",
    "tasks/db/validate_models.rake",
    "tasks/git.rake",
    "tasks/haml_sass.rake",
    "tasks/svn.rake"]
end