WebMock.disable_net_connect!

Hostess.local = true

TEST_DIR = File.join('/', 'tmp', 'gemcutter')

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

require 'factory_girl/step_definitions'

Before do
  WebMock.reset!
  DatabaseCleaner.start

  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)

  $fog.directories.create(:key => $rubygems_config[:s3_bucket], :public => true)
end

After do
  DatabaseCleaner.clean

  FileUtils.rm_rf(TEST_DIR)
  $redis.flushdb
end
