require File.dirname(__FILE__) + '/../test_helper'

class DependencyTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_validate_presence_of :name

  context "with a dependency" do
    setup do
      @dependency = Factory.build(:dependency)
    end

    should "have a rubygem name so it can be linked" do
      assert @dependency.respond_to?(:rubygem_name)
    end

    context "linking new rubygem" do
      setup do
        @name = "something"
        @dependency.rubygem_name = @name
        @dependency.save
      end
      should_change "Rubygem.count"
      should "link rubygem" do
        assert_equal @name, @dependency.rubygem.name
      end
    end

    context "linking existing rubygem" do
      setup do
        @rubygem = Factory(:rubygem)
        @dependency.rubygem_name = @rubygem.name
        @dependency.save
      end
      should "link rubygem" do
        assert_equal @rubygem, @dependency.rubygem
      end
    end
  end
end
