require File.dirname(__FILE__) + '/../test_helper'

class VersionTest < ActiveSupport::TestCase
  should_belong_to :rubygem
  should_have_many :dependencies
  should_have_many :downloads, :dependent => :destroy

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

    should "return just number for to_slug if platform is ruby" do
      assert ! @version.platformed?
      assert_equal @version.number, @version.to_slug
      assert_equal @version, Version.find_from_slug!(@version.rubygem_id, @version.number)
    end

    should "raise an ActiveRecord::RecordNotFound if an invalid slug is given" do
      assert_raise ActiveRecord::RecordNotFound do
        Version.find_from_slug!(@version.rubygem_id, "some stupid version 399")
      end
    end

    %w[x86_64-linux java mswin x86-mswin32-60].each do |platform|
      should "be able to deal with platform of #{platform}" do
        @version.update_attribute(:platform, platform)
        slug = "#{@version.number}-#{platform}"

        assert @version.platformed?
        assert_equal slug, @version.to_slug
        assert_equal @version, Version.find_from_slug!(@version.rubygem_id, slug)
      end
    end

    should "have a default download count" do
      assert @version.downloads_count.zero?
    end

    should "give no version flag for the latest version" do
      new_version = Factory(:version, :rubygem => @version.rubygem, :built_at => 1.day.from_now)

      assert_equal "gem install #{@version.rubygem.name} -v #{@version.number}", @version.to_install
      assert_equal "gem install #{new_version.rubygem.name}", new_version.to_install
    end

    should "tack on prerelease flag" do
      @version.update_attribute(:number, "0.3.0.pre")
      new_version = Factory(:version, :rubygem  => @version.rubygem,
                                      :built_at => 1.day.from_now,
                                      :number   => "0.4.0.pre")

      assert @version.prerelease
      assert new_version.prerelease

      assert_equal "gem install #{@version.rubygem.name} -v #{@version.number} --pre",
        @version.to_install
      assert_equal "gem install #{new_version.rubygem.name} --pre",
        new_version.to_install
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

    should "create a gem spec" do
      spec = @version.to_spec
      assert spec.is_a?(Gem::Specification)
      assert_equal @version.rubygem.name, spec.name
      assert_equal @version.number, spec.version.to_s
      assert_equal [@version.authors], spec.authors
      assert_equal @version.description, spec.description
      assert_equal @version.summary, spec.summary

      date = @version.built_at
      assert_equal Time.local(date.year, date.month, date.day), spec.date
    end

    should "join multiple authors on gemspecs" do
      @version.authors = "Geddy Lee, Neil Peart, Alex Lifeson"
      assert_equal ["Geddy Lee", "Neil Peart", "Alex Lifeson"], @version.to_spec.authors
    end

    should "create gemspec with some dependencies" do
      @dep_one = Factory(:dependency, :version => @version, :requirements => ">= 0, = 1.2.3")
      @dep_two = Factory(:dependency, :version => @version, :requirements => "= 3.0.0")
      spec = @version.to_spec

      assert_equal 2, spec.dependencies.size
      assert_equal @dep_one.rubygem.name, spec.dependencies.last.name
      assert_equal @dep_one.requirements.split(", "), spec.dependencies.last.requirements_list

      assert_equal @dep_two.rubygem.name, spec.dependencies.first.name
      assert_equal [@dep_two.requirements], spec.dependencies.first.requirements_list
    end
  end

  context "when indexing" do
    setup do
      @rubygem = Factory(:rubygem)
      @first_version  = Factory(:version, :rubygem => @rubygem, :number => "0.0.1", :built_at => 7.days.ago)
      @second_version = Factory(:version, :rubygem => @rubygem, :number => "0.0.2", :built_at => 6.days.ago)
      @third_version  = Factory(:version, :rubygem => @rubygem, :number => "0.0.3", :built_at => 5.days.ago)
      @fourth_version = Factory(:version, :rubygem => @rubygem, :number => "0.0.4", :built_at => 5.days.ago)
    end

    should "always sort properly" do
      assert_equal -1, (@first_version <=> @second_version)
      assert_equal -1, (@first_version <=> @third_version)
      assert_equal -1, (@first_version <=> @fourth_version)

      assert_equal 1,  (@second_version <=> @first_version)
      assert_equal -1, (@second_version <=> @third_version)
      assert_equal -1, (@second_version <=> @fourth_version)

      assert_equal 1,  (@third_version <=> @first_version)
      assert_equal 1,  (@third_version <=> @second_version)
      assert_equal -1, (@third_version <=> @fourth_version)

      assert_equal 1,  (@fourth_version <=> @first_version)
      assert_equal 1,  (@fourth_version <=> @second_version)
      assert_equal 1,  (@fourth_version <=> @third_version)
    end
  end

  context "with mixed release and prerelease versions" do
    setup do
      @prerelease = Factory(:version, :number => '1.0.rc1')
      @release    = Factory(:version, :number => '1.0')
    end

    should "know if it is a prelease version" do
      assert  @prerelease.prerelease?
      assert !@release.prerelease?
    end

    should "return prerelease gems from the prerelease named scope" do
      assert_equal [@prerelease], Version.prerelease
      assert_equal [@release],    Version.release
    end
  end

  context "with versions created out of order" do
    setup do
      @gem = Factory(:rubygem)
      Factory.create(:version, :rubygem => @gem, :number => '0.5')
      Factory.create(:version, :rubygem => @gem, :number => '0.3')
      Factory.create(:version, :rubygem => @gem, :number => '0.7')
      Factory.create(:version, :rubygem => @gem, :number => '0.2')
      @gem.reload # make sure to reload the versions just created
    end

    should "be in the proper order" do
      assert_equal ['0.7', '0.5', '0.3', '0.2'], @gem.versions.map(&:number)
    end

    should "know its latest version" do
      assert_equal '0.7', @gem.versions.latest.number
    end
  end

  context "with multiple rubygems and versions created out of order" do
    setup do
      @gem_one = Factory(:rubygem)
      @gem_two = Factory(:rubygem)
      @version_one_latest  = Factory.create(:version, :rubygem => @gem_one, :number => '0.2')
      @version_one_earlier = Factory.create(:version, :rubygem => @gem_one, :number => '0.1')
      @version_two_latest  = Factory.create(:version, :rubygem => @gem_two, :number => '1.0')
      @version_two_earlier = Factory.create(:version, :rubygem => @gem_two, :number => '0.5')
    end

    should "be able to fetch the latest versions" do
      assert_contains Version.latest, @version_one_latest
      assert_contains Version.latest, @version_two_latest

      assert_does_not_contain Version.latest, @version_one_earlier
      assert_does_not_contain Version.latest, @version_two_earlier
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
      @owned_one = Factory(:version, :rubygem => @gem, :built_at => 1.day.ago)
      @owned_two = Factory(:version, :rubygem => @gem, :built_at => 2.days.ago)
      @unowned   = Factory(:version)

      Factory(:ownership, :rubygem => @gem, :user => @user, :approved => true)
    end

    should "find versions that have other associated versions" do
      assert_equal [@owned_one, @owned_two], Version.with_associated
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
      assert ! @version.indexed
      assert_equal @spec.authors.join(', '), @version.authors
      assert_equal @spec.description,        @version.description
      assert_equal @spec.summary,            @version.summary
      assert_equal @spec.rubyforge_project,  @version.rubyforge_project
      assert_equal @spec.date,               @version.built_at
    end
  end
end
