require 'webmock'
WebMock.disable_net_connect!(:allow_localhost => true)

Hostess.local = true

TEST_DIR = File.join('/', 'tmp', 'gemcutter')

World(FactoryGirl::Syntax::Methods)

Before do
  WebMock.reset!
  FileUtils.mkdir(TEST_DIR)
  Dir.chdir(TEST_DIR)
  $fog.directories.create(:key => $rubygems_config[:s3_bucket], :public => true) if $fog
end

After do
  FileUtils.rm_rf(TEST_DIR)
  Dir.chdir(Rails.root)
  $redis.flushdb
end
