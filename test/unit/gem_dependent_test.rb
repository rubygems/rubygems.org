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
    end

    should "return an array with dependencies" do
      deps = GemDependent.new(["rack"]).to_a
      assert_equal(
        [{ name: "rack", number: "0.0.1", platform: "ruby", dependencies: [] }],
        deps
      )
    end
  end
end
