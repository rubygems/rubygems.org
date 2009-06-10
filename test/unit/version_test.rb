require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_have_many :requirements, :dependent => :destroy
  should_have_many :dependencies, :through => :requirements

  context "with a version" do
    setup do
      @version = Factory(:version)
    end

    should "give number for #to_s" do
      assert_equal @version.number, @version.to_s
    end
  end
end
