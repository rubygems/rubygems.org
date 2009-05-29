require File.dirname(__FILE__) + '/../test_helper'

class RubygemTest < ActiveSupport::TestCase
  should_belong_to :user
  should_have_many :versions
  should_have_many :dependencies

  should "be valid with factory" do
#    assert_valid Factory.build(:rubygem)
  end

  should "respond to data" do
    assert Rubygem.new.respond_to?(:data)
  end

  should "respond to spec" do
    assert Rubygem.new.respond_to?(:spec)
  end

  context "saving a gem" do
    setup do
      @gem = "test-0.0.0.gem"
      @gem_file = gem_file(@gem)
      @cache_path = Gemcutter.server_path("gems", @gem)

      regenerate_index

      @spec = Gem::Format.from_file_by_path(@gem_file.path).spec

      @rubygem = Rubygem.create(:data => @gem_file)
    end

    should "save the gem" do
      assert_not_nil @rubygem.spec
      assert_equal @spec.name, @rubygem.name
      assert !@rubygem.new_record?
      assert File.exists?(@cache_path)
      assert_equal 0100644, File.stat(@cache_path).mode
    end

    should "create a new version" do
      version = @rubygem.versions.first
      assert_not_nil version
      assert_equal @spec.authors, version.authors
      assert_equal @spec.summary, version.description
      assert_equal @spec.version, version.number
      assert !version.new_record?
    end

    should "update the index" do
      source_index = Gemcutter.server_path("source_index")
      assert File.exists?(source_index)

      source_index_data = File.open(source_index) { |f| Marshal.load f.read }
      assert source_index_data.gems.has_key?(@spec.original_name)

      quick_gem = Gemcutter.server_path("quick", "Marshal.4.8", "#{@spec.original_name}.gemspec.rz")
      assert File.exists?(quick_gem)

      quick_gem_data = File.open(quick_gem, 'rb') { |f| Marshal.load(Gem.inflate(f.read)) }
      assert_equal @rubygem.spec, quick_gem_data
    end
  end
end
