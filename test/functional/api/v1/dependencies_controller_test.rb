require 'test_helper'

class Api::V1::DependenciesControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @versions = [Factory(:version), Factory(:version)].each do |version|
        Factory(:dependency, :version => version)
      end
      get :index, :gems => @versions.map(&:rubygem).map(&:name).join(',')
    end

    should respond_with :success
    should "return Marshalled array of hashes" do
      array = Marshal.load(@response.body)
      assert_kind_of Array, array
      array.each {|hash| assert_kind_of Hash, hash }
    end
    should "return correct Marshalled values" do
      array = Marshal.load(@response.body)
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
      get :index, :gems => gems.join(',')
    end

    should respond_with :request_entity_too_large
    should "see too many gems text" do
      assert page.has_content?('Too many gems to resolve')
    end
  end
end
