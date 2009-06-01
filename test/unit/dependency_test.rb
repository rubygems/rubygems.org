require File.dirname(__FILE__) + '/../test_helper'

class DependencyTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_validate_presence_of :name, :requirement

  should "be valid with factory" do
    assert_valid Factory.build(:dependency)
  end
end
