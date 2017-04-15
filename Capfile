require 'capistrano/setup'
require 'capistrano/deploy'
require "capistrano/scm/git"

require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
# require 'capistrano/honeybadger'
require_relative 'lib/capistrano/git-submodule-strategy'

install_plugin Capistrano::SCM::Git
install_plugin Capistrano::SubmoduleStrategy

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
