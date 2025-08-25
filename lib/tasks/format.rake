desc "Format code with RuboCop and Prettier"
task format: %i[format:ruby format:js]

namespace :format do
  desc "Format Ruby code with RuboCop"
  task :ruby do
    sh "bin/rubocop --fix-layout"
  end

  desc "Format JavaScript code with Prettier"
  task :js do
    sh "bin/prettier --write 'app/javascript/**/*.js' 'config/*.js'"
  end
end
