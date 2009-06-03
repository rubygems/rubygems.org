require File.dirname(__FILE__) + '/../test_helper'

class LinksetTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_not_allow_mass_assignment_of :rubygem_id

  should "be valid with factory" do
    assert_valid Factory.build(:linkset)
  end
end
