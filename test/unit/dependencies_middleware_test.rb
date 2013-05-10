require 'test_helper'

class DependenciesMiddlewareTest < ActiveSupport::TestCase
  def setup
    super
    WebMock.stub_request(:any, /.*localhost:9200.*/).to_return(:body => '{}', :status => 200)
  end

  def app
    V1MarshaledDepedencies.new
  end

  context "on GET to index" do
    setup do
      @versions = [create(:version), create(:version)].each do |version|
        create(:dependency, :version => version)
      end
      get "/api/v1/dependencies",
          :gems => @versions.map(&:rubygem).map(&:name).join(',')
    end

    should "return Marshalled array of hashes" do
      assert_equal 200, last_response.status

      array = Marshal.load(last_response.body)
      assert_kind_of Array, array
      array.each {|hash| assert_kind_of Hash, hash }
    end

    should "return correct Marshalled values" do
      assert_equal 200, last_response.status

      array = Marshal.load(last_response.body)
      array.each_with_index do |hash, idx|
        assert_equal @versions[idx].rubygem.name, hash[:name]
        assert_equal @versions[idx].number, hash[:number]
        assert_kind_of Array, hash[:dependencies]
        assert_equal 1, hash[:dependencies].size
      end
    end
  end

  context "on GET to index with too many gems" do
    setup do
      gems = Array.new Dependency::LIMIT + 1, 'gem'
      get "/api/v1/dependencies", :gems => gems.join(',')
    end

    should "see too many gems text" do
      assert_match %r!Too many gems to resolve!, last_response.body
    end
  end

  context "on GET for an unknown gem" do
    setup do
      get "/api/v1/dependencies", :gems => "not-there"
    end

    should "return a 404 status" do
      assert_equal 404, last_response.status
    end
  end
end
