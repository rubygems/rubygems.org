ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

FakeWeb.allow_net_connect = false
set :environment, :test

Shoulda.autoload_macros(Rails.root, "vendor/bundler_gems/gems/*")

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end

class Test::Unit::TestCase
  include Webrat::Matchers
  include Rack::Test::Methods
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)

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

def create_gem(owner, opts = {})
  @rubygem = Factory(:rubygem, :name => opts[:name] || Factory.next(:name))
  Factory(:version, :rubygem => @rubygem)
  @rubygem.ownerships.create(:user => owner, :approved => true)
end

def gem_specification_from_gem_fixture(name)
  Gem::Format.from_file_by_path(File.join('test', 'gems', "#{name}.gem")).spec
end

def gem_dependency_stub(name, requirements = ">= 1.0")
  returning(Object.new) do |dependency|
    stub(dependency).name              { name }
    stub(dependency).requirements_list { requirements }
    stub(dependency).type              { 'runtime' }
  end
end

def stub_uploaded_token(gem_name, token, status = [200, "Success"])
  FakeWeb.register_uri(:get, "http://#{gem_name}.rubyforge.org/migrate-#{gem_name}.html", :body => token + "\n", :status => status)
end
