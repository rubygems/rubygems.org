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

      #regenerate_index
      @spec = "spec"
      stub(@spec).to_ruby
      stub(@spec).name { "test" }
      stub(@spec).version { "0.0.0" }
      stub(@spec).original_name { "test-0.0.0" }
      stub(@spec).authors { ["Joe User"] }
      stub(@spec).description { "Some awesome gem" }
      stub(@spec).dependencies { [] }
      stub(Gem::Format).from_file_by_path(@gem_file.path).stub!.spec { @spec }

      @rubygem = Rubygem.create(:data => @gem_file)
    end

    should "save the gem" do
      assert_equal @spec, @rubygem.spec
      assert_equal @spec.name, @rubygem.name
      assert !@rubygem.new_record?
      assert File.exists?(@cache_path)
      assert_equal 0100644, File.stat(@cache_path).mode
    end

    should "create a new version" do
      version = @rubygem.versions.first
      assert_not_nil version
      assert_equal @spec.authors, version.authors
      assert_equal @spec.description, version.description
      assert_equal @spec.version, version.number
      assert !version.new_record?
    end
  end
end
