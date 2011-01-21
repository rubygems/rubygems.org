WebMock.disable_net_connect!

Hostess.local = true

TEST_DIR = File.join('/', 'tmp', 'gemcutter')

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

Before do
  WebMock.reset_webmock
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
