require 'test_helper'

class ReverseDependencyTest < ActiveSupport::TestCase
  setup do
    dependency             = create(:rubygem)
    @reverse_dependency    = ReverseDependency.new(dependency.id)
    @gem_one               = create(:rubygem)
    @gem_two               = create(:rubygem)
    gem_three              = create(:rubygem)
    gem_four               = create(:rubygem)
    version_one            = create(:version, rubygem: @gem_one)
    version_two            = create(:version, rubygem: @gem_two)
    _version_three_latest  = create(:version, rubygem: gem_three, number: '1.0')
    version_three_earlier  = create(:version, rubygem: gem_three, number: '0.5')
    yanked_version         = create(:version, :yanked, rubygem: gem_four)

    create(:dependency, :runtime, version: version_one, rubygem: dependency)
    create(:dependency, :development, version: version_two, rubygem: dependency)
    create(:dependency, version: version_three_earlier, rubygem: dependency)
    create(:dependency, version: yanked_version, rubygem: dependency)
  end

  teardown do
    Rails.cache.clear
  end

  context "#legacy_find" do
    setup do
      @reverse_deps = @reverse_dependency.legacy_find
    end

    should "return dependent gems of latest indexed version" do
      assert_equal 2, @reverse_deps.size

      assert @reverse_deps.include?(@gem_one)
      assert @reverse_deps.include?(@gem_two)
      refute @reverse_deps.include?(@gem_three)
      refute @reverse_deps.include?(@gem_four)
    end
  end

  context "#runtime" do
    should "return runtime dependent rubygems" do
      gem_list = @reverse_dependency.runtime
      assert_equal 1, gem_list.size

      assert gem_list.include?(@gem_one)
      refute gem_list.include?(@gem_two)
    end
  end

  context "#development" do
    should "return development dependent rubygems" do
      gem_list = @reverse_dependency.development
      assert_equal 1, gem_list.size

      assert gem_list.include?(@gem_two)
      refute gem_list.include?(@gem_one)
    end
  end
end
