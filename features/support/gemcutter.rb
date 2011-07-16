Hostess.local = true

TEST_DIR = File.join('/', 'tmp', 'gemcutter')

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
