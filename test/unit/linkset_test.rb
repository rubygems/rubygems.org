require File.dirname(__FILE__) + '/../test_helper'

class LinksetTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_not_allow_mass_assignment_of :rubygem_id

  context "with a linkset" do
    setup do
      @linkset = Factory.build(:linkset)
    end

    should "be valid with factory" do
      assert_valid @linkset
    end

    should "not be empty with some links filled out" do
      assert !@linkset.empty?
    end

    should "be empty with no links filled out" do
      Linkset::LINKS.each do |link|
        @linkset.send("#{link}=", nil)
      end
      assert @linkset.empty?
    end
  end
end
