WebMock.disable_net_connect!

Hostess.local = true
Capybara.app_host = "https://gemcutter.local"

TEST_DIR = File.join('/', 'tmp', 'gemcutter')

require 'factory_girl/step_definitions'
World(FactoryGirl::Syntax::Methods)

Before do
  WebMock.reset!
  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)
  $fog.directories.create(:key => $rubygems_config[:s3_bucket], :public => true)
end

After do
  FileUtils.rm_rf(TEST_DIR)
  $redis.flushdb
end
