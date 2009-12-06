# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
require 'cucumber/formatter/unicode' # Comment out this line if you don't want Cucumber Unicode support
Cucumber::Rails.use_transactional_fixtures
Cucumber::Rails.bypass_rescue # Comment out this line if you want Rails own error handling 
                              # (e.g. rescue_action_in_public / rescue_responses / rescue_from)

require 'factory_girl'
Factory.find_definitions

require 'test/unit/assertions'
World(Test::Unit::Assertions)

require 'webrat'
Webrat.configure do |config|
  config.mode = :rails
end

require 'webrat/core/matchers'
require 'webrat/core/matchers/have_tag'

require 'fakeweb'
FakeWeb.allow_net_connect = false

TEST_DIR = File.join('/', 'tmp', 'gemcutter')
Hostess.local = true

Before do
  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)
end

After do
  Dir.chdir(TEST_DIR)
  FileUtils.rm_rf(TEST_DIR)
end
