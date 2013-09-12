Hostess.local = true
Capybara.app_host = "https://gemcutter.local"

TEST_DIR = File.join('/', 'tmp', 'gemcutter')

World(FactoryGirl::Syntax::Methods)

Before do
  WebMock.reset!
  FileUtils.mkdir_p(TEST_DIR)
  Dir.chdir(TEST_DIR)
  $fog.directories.create(:key => $rubygems_config[:s3_bucket], :public => true) if $fog
end

After do
  FileUtils.rm_rf(TEST_DIR)
  $redis.flushdb
end

Before('@search') do |s|
  Rails.logger.debug "[TIRE] Recreating the elasticsearch index"
  Rubygem.tire.index.delete
  Rubygem.tire.create_elasticsearch_index
end
