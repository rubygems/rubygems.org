require 'test_helper'

class VersionTest < ActiveSupport::TestCase
  should belong_to :rubygem
  should have_many :dependencies

  context "#as_json" do
    setup do
      @version = create(:version)
    end

    should "only have relevant API fields" do
      json = @version.as_json
      assert_equal %w[number built_at summary description authors platform ruby_version prerelease downloads_count licenses requirements sha metadata].map(&:to_s).sort, json.keys.sort
      assert_equal @version.authors, json["authors"]
      assert_equal @version.built_at, json["built_at"]
      assert_equal @version.description, json["description"]
      assert_equal @version.downloads_count, json["downloads_count"]
      assert_equal @version.metadata, json["metadata"]
      assert_equal @version.number, json["number"]
      assert_equal @version.platform, json["platform"]
      assert_equal @version.prerelease, json["prerelease"]
      assert_equal @version.ruby_version, json["ruby_version"]
      assert_equal @version.summary, json["summary"]
      assert_equal @version.licenses, json["licenses"]
      assert_equal @version.requirements, json["requirements"]
    end
  end

  context "#to_xml" do
    setup do
      @version = create(:version)
    end

    should "only have relevant API fields" do
      xml = Nokogiri.parse(@version.to_xml)
      assert_equal %w[number built-at summary description authors platform ruby-version prerelease downloads-count licenses requirements sha metadata].map(&:to_s).sort, xml.root.children.map{|a| a.name}.reject{|t| t == "text"}.sort
      assert_equal @version.authors, xml.at_css("authors").content
      assert_equal @version.built_at.to_i, xml.at_css("built-at").content.to_time.to_i
      assert_equal @version.description, xml.at_css("description").content
      assert_equal @version.downloads_count, xml.at_css("downloads-count").content.to_i
      assert_equal @version.metadata["foo"], xml.at_css("metadata foo").content
      assert_equal @version.number, xml.at_css("number").content
      assert_equal @version.platform, xml.at_css("platform").content
      assert_equal @version.prerelease.to_s, xml.at_css("prerelease").content
      assert_equal @version.ruby_version, xml.at_css("ruby-version").content
      assert_equal @version.summary.to_s, xml.at_css("summary").content
      assert_equal @version.licenses, xml.at_css("licenses").content
      assert_equal @version.requirements, xml.at_css("requirements").content
    end
  end

  context ".most_recent" do
    setup do
      @gem = create(:rubygem)
    end

    should "return most recently created version for versions with multiple non-ruby platforms" do
      create(:version, :rubygem => @gem, :number => '0.1', :platform => 'linux')
      @most_recent = create(:version, :rubygem => @gem, :number => '0.2', :platform => 'universal-rubinius')
      create(:version, :rubygem => @gem, :number => '0.1', :platform => 'mswin32')

      assert_equal @most_recent, Version.most_recent
    end
  end

  context ".reverse_dependencies" do
    setup do
      @dep_rubygem = create(:rubygem)
      @gem_one = create(:rubygem)
      @gem_two = create(:rubygem)
      @gem_three = create(:rubygem)
      @version_one_latest  = create(:version, :rubygem => @gem_one, :number => '0.2')
      @version_one_earlier = create(:version, :rubygem => @gem_one, :number => '0.1')
      @version_two_latest  = create(:version, :rubygem => @gem_two, :number => '1.0')
      @version_two_earlier = create(:version, :rubygem => @gem_two, :number => '0.5')
      @version_three = create(:version, :rubygem => @gem_three, :number => '1.7')

      @version_one_latest.dependencies << create(:dependency, :version => @version_one_latest, :rubygem => @dep_rubygem)
      @version_two_earlier.dependencies << create(:dependency, :version => @version_two_earlier, :rubygem => @dep_rubygem)
      @version_three.dependencies << create(:dependency, :version => @version_three, :rubygem => @dep_rubygem)
    end

    should "return all depended gem versions" do
      version_list = Version.reverse_dependencies(@dep_rubygem.name)

      assert_equal 3, version_list.size

      assert version_list.include?(@version_one_latest)
      assert version_list.include?(@version_two_earlier)
      assert version_list.include?(@version_three)
      assert ! version_list.include?(@version_one_earlier)
      assert ! version_list.include?(@version_two_latest)
    end
  end


  context "updated gems" do
    setup do
      Timecop.freeze Date.today
      @existing_gem = create(:rubygem)
      @second = create(:version, :rubygem => @existing_gem, :created_at => 1.day.ago)
      @fourth = create(:version, :rubygem => @existing_gem, :created_at => 4.days.ago)

      @another_gem = create(:rubygem)
      @third  = create(:version, :rubygem => @another_gem, :created_at => 3.days.ago)
      @first  = create(:version, :rubygem => @another_gem, :created_at => 1.minute.ago)
      @yanked = create(:version, :rubygem => @another_gem, :created_at => 30.seconds.ago)
      @yanked.yank!

      @bad_gem = create(:rubygem)
      @only_one = create(:version, :rubygem => @bad_gem, :created_at => 1.minute.ago)
    end

    teardown do
      Timecop.return
    end

    should "order gems by created at and show only gems that have more than one version" do
      versions = Version.just_updated
      assert_equal 4, versions.size
      assert_equal [@first, @second, @third, @fourth], versions
    end
  end

  context "with a rubygem" do
    setup do
      @rubygem = create(:rubygem)
    end

    should "not allow duplicate versions" do
      @version = build(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "ruby")
      @dup_version = @version.dup
      @number_version = build(:version, :rubygem => @rubygem, :number => "2.0.0", :platform => "ruby")
      @platform_version = build(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "mswin32")

      assert @version.save
      assert @number_version.save
      assert @platform_version.save
      assert ! @dup_version.valid?
    end

    should "be able to find dependencies" do
      @dependency = create(:rubygem)
      @version = build(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "ruby")
      @version.dependencies << create(:dependency, :version => @version, :rubygem => @dependency)
      assert ! Version.with_deps.first.dependencies.empty?
    end

    should "sort dependencies alphabetically" do
      @version = build(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "ruby")

      @first_dependency_by_alpha = create(:rubygem, :name => 'acts_as_indexed')
      @second_dependency_by_alpha = create(:rubygem, :name => 'friendly_id')
      @third_dependency_by_alpha = create(:rubygem, :name => 'refinerycms')

      @version.dependencies << create(:dependency, :version => @version, :rubygem => @second_dependency_by_alpha)
      @version.dependencies << create(:dependency, :version => @version, :rubygem => @third_dependency_by_alpha)
      @version.dependencies << create(:dependency, :version => @version, :rubygem => @first_dependency_by_alpha)

      assert @first_dependency_by_alpha.name, @version.dependencies.first.name
      assert @second_dependency_by_alpha.name, @version.dependencies[1].name
      assert @third_dependency_by_alpha.name, @version.dependencies.last.name
    end
  end

  context "with a ruby version" do
    setup do
      @ruby_version = ">= 1.9.3"
      @version = create(:version)
    end
    subject { @version }

    should "have a ruby version" do
      @version.ruby_version = @ruby_version
      @version.save!
      new_version = Version.find(@version.id)
      assert_equal new_version.ruby_version, @ruby_version
    end
  end

  context "without a ruby version" do
    setup do
      @ruby_version = ">= 1.9.3"
      @version = create(:version)
    end
    subject { @version }

    should "not have a ruby version" do
      @version.ruby_version = nil
      @version.save!
      nil_version = Version.find(@version.id)
      assert_nil nil_version.ruby_version
    end
  end

  context "with a version" do
    setup do
      @version = create(:version)
      @info = "some info"
    end
    subject { @version }

    should_not allow_value("#YAML<CEREALIZATION-FAIL>").for(:number)
    should_not allow_value("1.2.3-\"[javalol]\"").for(:number)
    should_not allow_value("0.8.45::Gem::PLATFORM::FAILBOAT").for(:number)
    should_not allow_value("1.2.3\n<bad>").for(:number)

    should allow_value("ruby").for(:platform)
    should allow_value("mswin32").for(:platform)
    should allow_value("x86_64-linux").for(:platform)
    should_not allow_value("Gem::Platform::Ruby").for(:platform)

    should "give number for #to_s" do
      assert_equal @version.number, @version.to_s
    end

    should "not be platformed" do
      assert ! @version.platformed?
    end

    should "save full name" do
      assert_equal "#{@version.rubygem.name}-#{@version.number}", @version.full_name
      assert_equal @version.number, @version.slug
    end

    should "save info into redis" do
      info = Redis.current.hgetall(Version.info_key(@version.full_name))
      assert_equal @version.rubygem.name, info["name"]
      assert_equal @version.number, info["number"]
      assert_equal @version.platform, info["platform"]
    end

    should "add version onto redis versions list" do
      assert_equal @version.full_name, Redis.current.lindex(Rubygem.versions_key(@version.rubygem.name), 0)
    end

    should "raise an ActiveRecord::RecordNotFound if an invalid slug is given" do
      assert_raise ActiveRecord::RecordNotFound do
        Version.find_from_slug!(@version.rubygem_id, "some stupid version 399")
      end
    end

    %w[x86_64-linux java mswin x86-mswin32-60].each do |platform|
      should "be able to find with platform of #{platform}" do
        version = create(:version, :platform => platform)
        slug = "#{version.number}-#{platform}"

        assert version.platformed?
        assert_equal version.reload, Version.find_from_slug!(version.rubygem_id, slug)
        assert_equal slug, version.slug
      end
    end

    should "have a default download count" do
      assert @version.downloads_count.zero?
    end

    should "give no version flag for the latest version" do
      new_version = create(:version, :rubygem => @version.rubygem, :built_at => 1.day.from_now)

      assert_equal "gem install #{@version.rubygem.name} -v #{@version.number}", @version.to_install
      assert_equal "gem install #{new_version.rubygem.name}", new_version.to_install
    end

    should "tack on prerelease flag" do
      @version.update_attributes(:number => "0.3.0.pre")
      new_version = create(:version, :rubygem  => @version.rubygem,
                            :built_at => 1.day.from_now,
                            :number   => "0.4.0.pre")

      assert @version.prerelease
      assert new_version.prerelease

      @version.rubygem.reorder_versions

      assert_equal "gem install #{@version.rubygem.name} -v #{@version.number} --pre",
        @version.to_install
      assert_equal "gem install #{new_version.rubygem.name} --pre",
        new_version.to_install
    end

    should "give no version count for the latest prerelease version" do
      @version.update_attributes(:number => "0.3.0.pre")
      old_version = create(:version, :rubygem  => @version.rubygem,
                            :built_at => 1.day.from_now,
                            :number   => "0.2.0")

      assert @version.prerelease
      assert !old_version.prerelease

      @version.rubygem.reorder_versions

      assert_equal "gem install #{@version.rubygem.name} --pre", @version.to_install
      assert_equal "gem install #{old_version.rubygem.name}", old_version.to_install
    end

    should "give title for #to_title" do
      assert_equal "#{@version.rubygem.name} (#{@version.to_s})", @version.to_title
    end

    should "give version with twiddle-wakka for #to_bundler" do
      assert_equal %{gem '#{@version.rubygem.name}', '~> #{@version.to_s}'}, @version.to_bundler
    end

    should "give title and platform for #to_title" do
      @version.platform = "zomg"
      assert_equal "#{@version.rubygem.name} (#{@version.number}-zomg)", @version.to_title
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

    should "give 'N/A' for size when size not available" do
      @version.size = nil
      assert_equal 'N/A', @version.size
    end

    context "when yanked" do
      setup do
        @version.yank!
      end
      should("unindex") { assert !@version.indexed? }
      should("be considered yanked") { assert Version.yanked.include?(@version) }
      should("no longer be latest") { assert !@version.latest?}
      should "not appear in the version list" do
        assert ! Redis.current.exists(Rubygem.versions_key(@version.rubygem.name))
      end
    end
  end

  context "with a very long authors string." do
    should "create without error" do

      create(:version, :authors => ["Fbdoorman: David Pelaez", "MiniFB:Appoxy", "Dan Croak", "Mike Burns", "Jason Morrison", "Joe Ferris", "Eugene Bolshakov", "Nick Quaranto", "Josh Nichols", "Mike Breen", "Marcel G\303\266rner", "Bence Nagy", "Ben Mabey", "Eloy Duran", "Tim Pope", "Mihai Anca", "Mark Cornick", "Shay Arnett", "Jon Yurek", "Chad Pytel"])
    end
  end

  context "when indexing" do
    setup do
      @rubygem = create(:rubygem)
      @first_version  = create(:version, :rubygem => @rubygem, :number => "0.0.1", :built_at => 7.days.ago)
      @second_version = create(:version, :rubygem => @rubygem, :number => "0.0.2", :built_at => 6.days.ago)
      @third_version  = create(:version, :rubygem => @rubygem, :number => "0.0.3", :built_at => 5.days.ago)
      @fourth_version = create(:version, :rubygem => @rubygem, :number => "0.0.4", :built_at => 5.days.ago)
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
      @prerelease = create(:version, :number => '1.0.rc1')
      @release    = create(:version, :number => '1.0')
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

  context "with only prerelease versions" do
    setup do
      @rubygem = create(:rubygem)
      @one = create(:version, :rubygem => @rubygem, :number => '1.0.0.pre')
      @two = create(:version, :rubygem => @rubygem, :number => '1.0.1.pre')
      @three = create(:version, :rubygem => @rubygem, :number => '1.0.2.pre')
      @rubygem.reload
    end

    should "show last pushed as latest version" do
      assert_equal @three, @rubygem.versions.most_recent
    end
  end

  context "with versions created out of order" do
    setup do
      @gem = create(:rubygem)
      create(:version, :rubygem => @gem, :number => '0.5')
      create(:version, :rubygem => @gem, :number => '0.3')
      create(:version, :rubygem => @gem, :number => '0.7')
      create(:version, :rubygem => @gem, :number => '0.2')
      @gem.reload # make sure to reload the versions just created
    end

    should "be in the proper order" do
      assert_equal %w[0.7 0.5 0.3 0.2], @gem.versions.by_position.map(&:number)
    end

    should "know its latest version" do
      assert_equal '0.7', @gem.versions.most_recent.number
    end
  end

  context "with multiple rubygems and versions created out of order" do
    setup do
      @gem_one = create(:rubygem)
      @gem_two = create(:rubygem)
      @version_one_latest  = create(:version, :rubygem => @gem_one, :number => '0.2')
      @version_one_earlier = create(:version, :rubygem => @gem_one, :number => '0.1')
      @version_two_latest  = create(:version, :rubygem => @gem_two, :number => '1.0')
      @version_two_earlier = create(:version, :rubygem => @gem_two, :number => '0.5')
    end

    should "be able to fetch the latest versions" do
      assert_contains Version.latest.map(&:id), @version_one_latest.id
      assert_contains Version.latest.map(&:id), @version_two_latest.id

      assert_does_not_contain Version.latest.map(&:id), @version_one_earlier.id
      assert_does_not_contain Version.latest.map(&:id), @version_two_earlier.id
    end
  end

  context "with a few versions" do
    setup do
      @thin = create(:version, :authors => %w[thin], :built_at => 1.year.ago)
      @rake = create(:version, :authors => %w[rake], :built_at => 1.month.ago)
      @json = create(:version, :authors => %w[json], :built_at => 1.week.ago)
      @thor = create(:version, :authors => %w[thor], :built_at => 2.days.ago)
      @rack = create(:version, :authors => %w[rack], :built_at => 1.day.ago)
      @haml = create(:version, :authors => %w[haml], :built_at => 1.hour.ago)
      @dust = create(:version, :authors => %w[dust], :built_at => 1.day.from_now)
      @fake = create(:version, :authors => %w[fake], :indexed => false, :built_at => 1.minute.ago)
    end

    should "get the latest versions up to today" do
      assert_equal [@haml, @rack, @thor, @json, @rake].map(&:authors),        Version.published(5).map(&:authors)
      assert_equal [@haml, @rack, @thor, @json, @rake, @thin].map(&:authors), Version.published(6).map(&:authors)
    end
  end

  context "with a few versions some owned by a user" do
    setup do
      @user      = create(:user)
      @gem       = create(:rubygem)
      @owned_one = create(:version, :rubygem => @gem, :built_at => 1.day.ago)
      @owned_two = create(:version, :rubygem => @gem, :built_at => 2.days.ago)
      @unowned   = create(:version)

      create(:ownership, :rubygem => @gem, :user => @user)
    end

    should "return the owned gems from #owned_by" do
      assert_contains Version.owned_by(@user).map(&:id), @owned_one.id
      assert_contains Version.owned_by(@user).map(&:id), @owned_two.id
    end

    should "not return the unowned versions from #owned_by" do
      assert_does_not_contain Version.owned_by(@user).map(&:id), @unowned.id
    end
  end

  context "with a few versions some subscribed to by a user" do
    setup do
      @user           = create(:user)
      @gem            = create(:rubygem)
      @subscribed_one = create(:version, :rubygem => @gem)
      @subscribed_two = create(:version, :rubygem => @gem)
      @unsubscribed   = create(:version)

      create(:subscription, :rubygem => @gem, :user => @user)
    end

    should "return the owned gems from #owned_by" do
      assert_contains Version.subscribed_to_by(@user).map(&:id), @subscribed_one.id
      assert_contains Version.subscribed_to_by(@user).map(&:id), @subscribed_two.id
    end

    should "not return the unowned versions from #owned_by" do
      assert_does_not_contain Version.subscribed_to_by(@user).map(&:id), @unsubscribed.id
    end

    should "order them from latest-oldest pushed to Gemcutter, not build data" do
      # Setup so that gem one was built earlier than gem two, but pushed to Gemcutter after gem two
      # We do this so that:
      #  a) people with RSS will get smooth results, rather than gem versions jumping around the place
      #  b) people can't hijack the latest gem spot by building in the far future, but pushing today
      @subscribed_one.update_attributes(:built_at => Time.now - 3.days, :created_at => Time.now - 1.day)
      @subscribed_two.update_attributes(:built_at => Time.now - 2.days, :created_at => Time.now - 2.days)

      # Even though gem two was build before gem one, it was pushed to gemcutter first
      # Thus, we should have from newest to oldest, gem one, then gem two
      expected = [@subscribed_one, @subscribed_two].map do |s|
        s.created_at.to_s(:db)
      end
      actual = Version.subscribed_to_by(@user).map do |s|
        s.created_at.to_s(:db)
      end
      assert_equal expected, actual
    end
  end

  context "with a Gem::Specification" do
    setup do
      @spec    = new_gemspec "test", "1.0.0", "a test gem", "ruby"
      @version = build(:version)
    end

    [/foo/, 1337, {:foo => "bar"}].each do |example|
      should "be invalid with authors as an Array of #{example.class}'s" do
        assert_raise ActiveRecord::RecordInvalid do
          @spec.authors = [example]
          @version.update_attributes_from_gem_specification!(@spec)
        end
      end
    end

    should "have attributes set properly from the specification" do
      @version.update_attributes_from_gem_specification!(@spec)

      assert @version.indexed
      assert_equal @spec.authors.join(', '),  @version.authors
      assert_equal @spec.description,         @version.description
      assert_equal @spec.summary,             @version.summary
      assert_equal @spec.date,                @version.built_at
      assert_equal @spec.metadata,            @version.metadata
    end
  end

  context "indexes" do
    setup do
      @first_rubygem  = create(:rubygem, :name => "first")
      @second_rubygem = create(:rubygem, :name => "second")

      @first_version  = create(:version, :rubygem => @first_rubygem,  :number => "0.0.1", :platform => "ruby")
      @second_version = create(:version, :rubygem => @first_rubygem,  :number => "0.0.2", :platform => "ruby")
      @other_version  = create(:version, :rubygem => @second_rubygem, :number => "0.0.2", :platform => "java")
      @pre_version    = create(:version, :rubygem => @second_rubygem, :number => "0.0.2.pre", :platform => "java", :prerelease => true)
    end

    should "select only name, version, and platform for all gems" do
      assert_equal [
        ["first",  "0.0.1", "ruby"],
        ["first",  "0.0.2", "ruby"],
        ["second", "0.0.2", "java"]
      ], Version.rows_for_index
    end

    should "select only name, version, and platform for recent gems" do
      assert_equal [
        ["first",  "0.0.2", "ruby"],
        ["second", "0.0.2", "java"]
      ], Version.rows_for_latest_index
    end

    should "select only name, version, and platform for prerelease gems" do
      assert_equal [
        ["second", "0.0.2.pre", "java"]
      ], Version.rows_for_prerelease_index
    end
  end

  context "checksums" do
    setup do
      @version = create(:version)
    end

    should "be available from the database" do
      assert_equal "tdQEXD9Gb6kf4sxqvnkjKhpXzfEE96JucW4KHieJ33g=", @version.reload.sha256
    end

    should "convert to hex on sha256_hex" do
      assert_equal "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78", @version.reload.sha256_hex
    end

    should "should return nil on sha256_hex when sha not avaible" do
      version = create(:version, sha256: nil)
      assert_nil version.sha256_hex
    end
  end
end
