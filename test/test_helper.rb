ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails/test_help'

set :environment, :test

WebMock.disable_net_connect!(:allow => 'localhost:8981')

require 'clearance/shoulda_macros'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  ActionDispatch::TestRequest::DEFAULT_ENV['HTTPS'] = 'on'
end

class Test::Unit::TestCase
  include Webrat::Matchers
  include Rack::Test::Methods
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)
  include WebMock

  def setup
    RR.reset
    $redis.flushdb
    $fog.directories.create(:key => $rubygems_config[:s3_bucket], :public => true)
  end

  def response_body
    @response.body
  end

  def assert_changed(object, attribute, &block)
    original = object.send(attribute)
    yield
    latest = object.reload.send(attribute)
    assert_not_equal original, latest,
      "Expected #{object.class} #{attribute} to change but still #{latest}"
  end
end

def regenerate_index
  FileUtils.rm_rf(
    %w[server/cache/*
    server/*specs*
    server/quick
    server/specifications
    server/source_index].map { |d| Dir[d] })
end

def create_gem(*owners_and_or_opts)
  opts, owners = owners_and_or_opts.extract_options!, owners_and_or_opts
  @rubygem = Factory(:rubygem, :name => opts[:name] || Factory.next(:name))
  Factory(:version, :rubygem => @rubygem)
  owners.each { |owner| @rubygem.ownerships.create(:user => owner, :approved => true) }
end

def gem_specification_from_gem_fixture(name)
  Gem::Format.from_file_by_path(File.join('test', 'gems', "#{name}.gem")).spec
end

def stub_uploaded_token(gem_name, token, status = [200, "Success"])
  WebMock.stub_request(:get,
                       "http://#{gem_name}.rubyforge.org/migrate-#{gem_name}.html").
    to_return(:body => token + "\n", :status => status)
end

###
# Stubbing for calls to Solr
##

# Ignore all calls to update documents
# WebMock.stub_http_request(:post, %r{http://localhost:8981/solr/update})

# Build a search response body for the given gems
def mock_solr_search_response(*gems)
  docs = [gems].flatten.collect do |rubygem|
    "{'id' => 'Rubygem #{rubygem.id}'}"
  end.join(",")
  "{'response' => {'docs'=>[#{docs}]}}"
end

# Mock a search request and response for the given gems
def stub_solr_select(*gems)
  WebMock.stub_http_request(:get, %r{http://localhost:8981/solr/select}).to_return(
    :body => mock_solr_search_response(*gems)
  )
end
