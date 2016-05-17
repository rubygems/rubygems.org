require 'test_helper'

class GemDependentTest < ActiveSupport::TestCase
  context "creating a new dependency_api" do
    setup do
      @gem = create(:rubygem)
      @gem_dependent = GemDependent.new(@gem.name)
    end

    should "have some state" do
      assert @gem_dependent.respond_to?(:gem_names)
    end
  end

  context "no gem_names" do
    should "return an ArgumentError" do
      assert_raises ArgumentError do
        GemDependent.new.to_a
      end
    end
  end

  context "with gem_names" do
    setup do
      @gem = create(:rubygem, name: "rack")
      create(:version, number: "0.0.1", rubygem_id: @gem.id)
      create(:version, number: "0.0.2", rubygem_id: @gem.id)

      @gem2 = create(:rubygem, name: "rack2")
      create(:version, number: "0.0.1", rubygem_id: @gem2.id)
    end

    should "return an array with dependencies" do
      deps = GemDependent.new(["rack2"]).to_a
      assert_equal(
        [{ name: "rack2", number: "0.0.1", platform: "ruby", dependencies: [] }],
        deps
      )
    end

    should "return all versions for a gem" do
      deps = GemDependent.new(["rack"]).to_a
      assert_equal(
        [
          { name: "rack", number: "0.0.2", platform: "ruby", dependencies: [] },
          { name: "rack", number: "0.0.1", platform: "ruby", dependencies: [] }
        ],
        deps
      )
    end
  end
end
