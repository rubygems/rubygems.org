require "test_helper"

class ApplicationModelTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  context "with an uninitialized object" do
    setup do
      @model = ApplicationModel.allocate
    end

    should "inspect as not initializee" do
      assert_match " not initialized", @model.inspect
    end

    should "pretty_inspect as not initializee" do
      assert_match " not initialized", @model.pretty_inspect
    end
  end

  context "with no attributes" do
    setup do
      @model = ApplicationModel.new({})
    end

    should "inspect" do
      assert_equal "#<ApplicationModel >", @model.inspect
    end

    should "pretty_inspect" do
      assert_match(/#<ApplicationModel:0x[0-9a-f]+>/, @model.pretty_inspect)
    end

    should "compare equal to itself" do
      assert_equal @model, @model.itself
    end

    should "compare equal to a copy" do
      assert_equal @model, ApplicationModel.new({})
    end
  end
end
