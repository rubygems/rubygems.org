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
      create(:version, number: "0.0.1", created_at: Date.new(2016, 05, 24), rubygem_id: @gem2.id)
    end

    should "return rack2" do
      result = {
        name:                "rack2",
        number:              "0.0.1",
        platform:            "ruby",
        rubygems_version:    ">= 2.6.3",
        ruby_version:        ">= 2.0.0",
        checksum:            "tdQEXD9Gb6kf4sxqvnkjKhpXzfEE96JucW4KHieJ33g=",
        created_at:          Date.new(2016, 05, 24),
        dependencies: []
      }

      deps = GemDependent.new(["rack2"]).to_a
      result.each_pair do |k, v|
        assert_equal v, deps.first[k]
      end
    end

    should "return all versions for a gem" do
      result = %w(0.0.2 0.0.1)

      deps = GemDependent.new(["rack"]).to_a
      assert_equal result, deps.map { |x| x[:number] }
    end
  end

  context "with gem_names which do not exist" do
    should "return empty array" do
      assert_equal [], GemDependent.new(["does_not_exist"]).to_a
    end
  end
end
