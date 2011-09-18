ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'clearance/testing'
require 'capybara/rails'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  ActionDispatch::TestRequest::DEFAULT_ENV['HTTPS'] = 'on'
end

class Test::Unit::TestCase
  include Rack::Test::Methods
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)
  include WebMock::API

  def setup
    RR.reset
    $redis.flushdb
    $fog.directories.create(:key => $rubygems_config[:s3_bucket], :public => true)
  end

  def page
    Capybara::Node::Simple.new(@response.body)
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
  @rubygem = Factory(:rubygem, :name => opts[:name] || FactoryGirl.generate(:name))
  Factory(:version, :rubygem => @rubygem)
  owners.each { |owner| @rubygem.ownerships.create(:user => owner) }
end

def gem_specification_from_gem_fixture(name)
  Gem::Format.from_file_by_path(File.join('test', 'gems', "#{name}.gem")).spec
end

def stub_uploaded_token(gem_name, token, status = [200, "Success"])
  WebMock.stub_request(:get, "http://#{gem_name}.rubyforge.org/migrate-#{gem_name}.html").
    to_return(:body => token + "\n", :status => status)
end

def gem_spec(opts = {})
  Gem::Specification.new do |s|
    s.name = %q{test}
    s.version = opts[:version] || "0.0.0"
    s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
    s.authors = ["Joe User"]
    s.description = %q{This is my awesome gem.}
    s.email = %q{joe@user.com}
    s.files = [
      "README.textile",
      "Rakefile",
      "VERSION.yml",
      "lib/test.rb",
      "test/test_test.rb"
    ]
    s.homepage = %q{http://user.com/test}
  end
end

def gem_file(name = "test-0.0.0.gem")
  File.open(File.expand_path("../gems/#{name}", __FILE__))
end
