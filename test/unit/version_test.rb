require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_have_many :requirements, :dependent => :destroy
  should_have_many :dependencies, :through => :requirements

  context "with a rubygem" do
    setup do
      @rubygem = Factory(:rubygem)
    end

    should "not allow duplicate versions" do
      @version = Factory.build(:version, :rubygem => @rubygem, :number => "1.0.0")
      @version_dup = @version.dup

      assert @version.save
      assert ! @version_dup.valid?
    end
  end

  context "with a version" do
    setup do
      @version = Factory(:version)
      @info = "some info"
    end
    subject { @version }

    should_not_allow_values_for :number, "#YAML<CEREALIZATION-FAIL>",
                                         "1.2.3-\"[javalol]\"",
                                         "0.8.45::Gem::PLATFORM::FAILBOAT"


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

    should "have summary for info if description is blank" do
      @version.description = ""
      @version.summary = @info
      assert_equal @info, @version.info
    end

    should "have some text for info if neither summary or description exist" do
      @version.description = nil
      @version.summary = nil
      assert_equal "This rubygem does not have a description or summary.", @version.info
    end
  end

  context "with a few versions" do
    setup do
      @thin = Factory(:version, :authors => "thin", :created_at => 1.year.ago)
      @rake = Factory(:version, :authors => "rake", :created_at => 1.month.ago)
      @json = Factory(:version, :authors => "json", :created_at => 1.week.ago)
      @thor = Factory(:version, :authors => "thor", :created_at => 2.days.ago)
      @rack = Factory(:version, :authors => "rack", :created_at => 1.day.ago)
      @haml = Factory(:version, :authors => "haml", :created_at => 1.hour.ago)
      @dust = Factory(:version, :authors => "dust", :created_at => 1.day.from_now)
    end

    should "get the latest versions up to today" do
      assert_equal [@haml, @rack, @thor, @json, @rake].map(&:authors), Version.published.map(&:authors)
    end
  end
end
