require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_have_many :requirements, :dependent => :destroy
  should_have_many :dependencies, :through => :requirements
  should_not_allow_values_for :number, "#YAML<CEREALIZATION-FAIL>",
                                       "1.2.3-\"[javalol]\"",
                                       "0.8.45::Gem::PLATFORM::FAILBOAT"

  context "with a version" do
    setup do
      @version = Factory(:version)
      @info = "some info"
    end

    should "give number for #to_s" do
      assert_equal @version.number, @version.to_s
    end

    should "have description for info" do
      @version.description = @info
      assert_equal @info, @version.info
    end

    should "have summary for info if description does not exist" do
      @version.description = nil
      @version.summary = @info
      assert_equal @info, @version.info
    end

    should "have some text for info if neither summary or description exist" do
      @version.description = nil
      @version.summary = nil
      assert_equal "This rubygem does not have a description or summary.", @version.info
    end
  end
end
