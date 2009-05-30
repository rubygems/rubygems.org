require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should_belong_to :rubygem

  context "with a version" do
    setup do
      @version = Factory(:version)
    end

    should "give number for #to_s" do
      assert_equal @version.number, @version.to_s
    end
  end
end
