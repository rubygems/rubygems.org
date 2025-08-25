desc "Format code with RuboCop and Prettier"
task format: :environment do
  Rake::Task["format:ruby"].invoke
  Rake::Task["format:js"].invoke
end

namespace :format do
  desc "Format Ruby code with RuboCop"
  task ruby: :environment do
    sh "bundle exec rubocop -a"
  end

  desc "Format JavaScript code with Prettier"
  task js: :environment do
    sh "npx prettier@3 --write 'app/javascript/**/*.js' 'config/*.js'"
  end
end
