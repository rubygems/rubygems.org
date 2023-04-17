require "test_helper"

class OIDC::BaseModelTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  context "with an uninitialized object" do
    setup do
      @model = OIDC::BaseModel.allocate
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
      @model = OIDC::BaseModel.new({})
    end

    should "inspect" do
      assert_equal "#<OIDC::BaseModel >", @model.inspect
    end

    should "pretty_inspect" do
      assert_match(/#<OIDC::BaseModel:0x[0-9a-f]+>/, @model.pretty_inspect)
    end

    should "compare equal to itself" do
      assert_equal @model, @model.itself
    end

    should "compare equal to a copy" do
      assert_equal @model, OIDC::BaseModel.new({})
    end
  end
end
