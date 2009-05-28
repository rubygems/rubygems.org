require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should_belong_to :rubygem

  should "respond to data" do
    assert Version.new.respond_to?(:data)
  end

  context "saving a gem" do
    setup do
      @rubygem = Rubygem.new
      @gem_file = gem_file("test-0.0.0.gem")
      @temp_path = "temp path"

      mock.proxy(Tempfile).new("gem") do |file|
        @temp_file = file
      end
      #regenerate_index
    end

    should "save a gem" do
      Factory(:version, :data => @gem_file)
      assert File.exists?(@temp_file)
      assert FileUtils.compare_file(@temp_file.path, @gem_file.path)
    end
  end
end
