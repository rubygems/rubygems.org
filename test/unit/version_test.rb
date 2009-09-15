require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_have_many :dependencies

  context "with a rubygem" do
    setup do
      @rubygem = Factory(:rubygem)
    end

    should "not allow duplicate versions" do
      @version = Factory.build(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "ruby")
      @dup_version = @version.dup
      @number_version = Factory.build(:version, :rubygem => @rubygem, :number => "2.0.0", :platform => "ruby")
      @platform_version = Factory.build(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "mswin32")

      assert @version.save
      assert @number_version.save
      assert @platform_version.save
      assert ! @dup_version.valid?
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

    should "give no version flag for the latest version" do
      new_version = Factory(:version, :rubygem => @version.rubygem, :built_at => 1.day.from_now)

      assert_equal "gem install #{@version.rubygem.name} -v #{@version.number}", @version.to_install
      assert_equal "gem install #{new_version.rubygem.name}", new_version.to_install
    end

    should "give title for #to_title" do
      assert_equal "#{@version.rubygem.name} (#{@version.to_s})", @version.to_title
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
      assert_equal [@haml, @rack, @thor, @json, @rake].map(&:authors),        Version.published.map(&:authors)
      assert_equal [@haml, @rack, @thor, @json, @rake, @thin].map(&:authors), Version.published(6).map(&:authors)
    end
  end

  context "with a few versions some owned by a user" do
    setup do
      @user      = Factory(:user)
      @gem       = Factory(:rubygem)
      @owned_one = Factory(:version, :rubygem => @gem)
      @owned_two = Factory(:version, :rubygem => @gem)
      @unowned   = Factory(:version)

      Factory(:ownership, :rubygem => @gem, :user => @user, :approved => true)
    end

    should "return the owned gems from #owned_by" do
      assert_contains Version.owned_by(@user), @owned_one
      assert_contains Version.owned_by(@user), @owned_two
    end

    should "not return the unowned versions from #owned_by" do
      assert_does_not_contain Version.owned_by(@user), @unowned
    end
  end

  context "with a few versions some subscribed to by a user" do
    setup do
      @user           = Factory(:user)
      @gem            = Factory(:rubygem)
      @subscribed_one = Factory(:version, :rubygem => @gem)
      @subscribed_two = Factory(:version, :rubygem => @gem)
      @unsubscribed   = Factory(:version)

      Factory(:subscription, :rubygem => @gem, :user => @user)
    end

    should "return the owned gems from #owned_by" do
      assert_contains Version.subscribed_to_by(@user), @subscribed_one
      assert_contains Version.subscribed_to_by(@user), @subscribed_two
    end

    should "not return the unowned versions from #owned_by" do
      assert_does_not_contain Version.subscribed_to_by(@user), @unsubscribed
    end
  end

  context "with a Gem::Specification" do
    setup do
      @spec    = gem_specification_from_gem_fixture('test-0.0.0')
      @version = Factory(:version)
      @version.update_attributes_from_gem_specification!(@spec)
    end

    should "have attributes set properly from the specification" do
      assert_equal @spec.authors.join(', '), @version.authors
      assert_equal @spec.description,        @version.description
      assert_equal @spec.summary,            @version.summary
      assert_equal @spec.rubyforge_project,  @version.rubyforge_project
      assert_equal @spec.date,               @version.built_at
    end
  end
end
