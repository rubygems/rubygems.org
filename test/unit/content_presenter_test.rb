require "test_helper"

class ContentPresenterTest < ActiveSupport::TestCase
  setup do
    @viewer = ContentPresenter.new(@version.manifest)
    puts @viewer.pretty_inspect
  end

  context "#leaf?" do
    should "return true for a leaf" do
      assert @viewer.leaf?("README")
    end
  end

  context "#ls" do
    should "return the root level of the tree" do
      assert_equal %w[bin lib README], @viewer.ls.map(&:to_s)
    end

    should "return a directory in the tree" do
      assert_equal %w[bin lib README], @viewer.ls("bin/").map(&:to_s)
    end
  end
end
