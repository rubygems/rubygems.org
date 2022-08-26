desc "Generate an ERD for the app"
task :gen_erd do
  title = "RubyGems.org domain model"
  `bundle exec rake erd filetype=svg filename=doc/erd orientation=vertical title="#{title}"`
  `bundle exec rake erd filetype=dot filename=doc/erd orientation=vertical title="#{title}"`
end
