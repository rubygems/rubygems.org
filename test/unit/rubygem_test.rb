require File.dirname(__FILE__) + '/../test_helper'

class RubygemTest < ActiveSupport::TestCase
  context "with a saved rubygem" do
    setup do
      @rubygem = Factory(:rubygem, :name => "SomeGem")
    end
    subject { @rubygem }

    should have_many(:owners).through(:ownerships)
    should have_many(:ownerships).dependent(:destroy)
    should have_many(:subscriptions).dependent(:destroy)
    should have_many(:versions).dependent(:destroy)
    should have_many(:web_hooks).dependent(:destroy)
    should have_one(:linkset).dependent(:destroy)
    should validate_uniqueness_of :name
    should allow_value("rails").for(:name)
    should allow_value("awesome42").for(:name)
    should allow_value("factory_girl").for(:name)
    should allow_value("rack-test").for(:name)
    should allow_value("perftools.rb").for(:name)
    should_not allow_value("\342\230\203").for(:name)

    should "reorder versions with platforms properly" do
      version3_ruby  = Factory(:version, :rubygem => @rubygem, :number => "3.0.0", :platform => "ruby")
      version3_mswin = Factory(:version, :rubygem => @rubygem, :number => "3.0.0", :platform => "mswin")
      version2_ruby  = Factory(:version, :rubygem => @rubygem, :number => "2.0.0", :platform => "ruby")
      version1_linux = Factory(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "linux")

      @rubygem.reorder_versions

      assert_equal 0, version3_ruby.reload.position
      assert_equal 0, version3_mswin.reload.position
      assert_equal 1, version2_ruby.reload.position
      assert_equal 2, version1_linux.reload.position

      latest_versions = Version.latest
      assert latest_versions.include?(version3_ruby)
      assert latest_versions.include?(version3_mswin)

      assert_equal version3_ruby, @rubygem.versions.most_recent
    end

    should "order latest platform gems with latest uniquely" do
      pre  = Factory(:version, :rubygem => @rubygem, :number => "1.5.0.pre", :platform => "ruby", :prerelease => true)
      ming = Factory(:version, :rubygem => @rubygem, :number => "1.4.2.1", :platform => "x86-mingw32")
      win  = Factory(:version, :rubygem => @rubygem, :number => "1.4.2.1", :platform => "x86-mswin32")
      ruby = Factory(:version, :rubygem => @rubygem, :number => "1.4.2", :platform => "ruby")
      java = Factory(:version, :rubygem => @rubygem, :number => "1.4.2", :platform => "java")
      old  = Factory(:version, :rubygem => @rubygem, :number => "1.4.1", :platform => "ruby")

      @rubygem.reorder_versions

      assert ! pre.reload.latest
      assert ! old.reload.latest
      assert ming.reload.latest
      assert win.reload.latest
      assert ruby.reload.latest
      assert java.reload.latest
    end

    should "not return platform gem for latest if the ruby version is old" do
      version3_mswin = Factory(:version, :rubygem => @rubygem, :number => "3.0.0", :platform => "mswin")
      version2_ruby  = Factory(:version, :rubygem => @rubygem, :number => "2.0.0", :platform => "ruby")

      @rubygem.reorder_versions

      assert_equal version2_ruby.reload, @rubygem.versions.most_recent
      assert version3_mswin.reload.latest
    end

    should "not have a most recent version if no versions exist" do
      assert_nil @rubygem.versions.most_recent
    end

    should "return the ruby version for most_recent if one exists" do
      version3_mswin = Factory(:version, :rubygem => @rubygem, :number => "3.0.0", :platform => "mswin", :built_at => 1.year.from_now)
      version3_ruby  = Factory(:version, :rubygem => @rubygem, :number => "3.0.0", :platform => "ruby")

      @rubygem.reorder_versions

      assert_equal version3_ruby, @rubygem.versions.most_recent
    end

    should "can find when the first built date was" do
      Timecop.travel(DateTime.now) do
        Factory(:version, :rubygem => @rubygem, :number => "3.0.0", :built_at => 1.day.ago)
        Factory(:version, :rubygem => @rubygem, :number => "2.0.0", :built_at => 2.days.ago)
        Factory(:version, :rubygem => @rubygem, :number => "1.0.0", :built_at => 3.days.ago)
        Factory(:version, :rubygem => @rubygem, :number => "1.0.0.beta", :built_at => 4.days.ago)

        assert_equal 4.days.ago.to_date, @rubygem.first_built_date.to_date
      end
    end

    should "have a most_recent version if only a platform version exists" do
      version1 = Factory(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "linux")

      assert_equal version1, @rubygem.reload.versions.most_recent
    end

    should "return the release version for most_recent if one exists" do
      version2pre = Factory(:version, :rubygem => @rubygem, :number => "2.0.pre", :platform => "ruby")
      version1 = Factory(:version, :rubygem => @rubygem, :number => "1.0.0", :platform => "ruby")

      assert_equal version1, @rubygem.reload.versions.most_recent
    end

    should "have a most_recent version if only a prerelease version exists" do
      version1pre = Factory(:version, :rubygem => @rubygem, :number => "1.0.pre", :platform => "ruby")

      assert_equal version1pre, @rubygem.reload.versions.most_recent
    end

    should "return the most_recent indexed version when a more recent yanked version exists" do
      indexed_v1 = Factory(:version, :rubygem => @rubygem, :number => "0.1.0", :indexed => true)
      yanked_v2  = Factory(:version, :rubygem => @rubygem, :number => "0.1.1", :indexed => false)

      assert_equal indexed_v1.reload, @rubygem.reload.versions.most_recent
    end
  end

  context "with a rubygem" do
    setup do
      @rubygem = FactoryGirl.build(:rubygem, :linkset => nil)
    end

    ['1337', 'Snakes!', ['zomg']].each do |bad_name|
      should "not accept #{bad_name.inspect} as a name" do
        @rubygem.name = bad_name
        assert ! @rubygem.valid?
        assert_match /Name/, @rubygem.all_errors
      end
    end

    should "return linkset errors in #all_errors" do
      @specification = gem_specification_from_gem_fixture('test-0.0.0')
      @specification.homepage = "badurl.com"

      assert_raise ActiveRecord::RecordInvalid do
        @rubygem.update_linkset!(@specification)
      end

      assert_equal "Home does not appear to be a valid URL", @rubygem.all_errors
    end

    should "return version errors in #all_errors" do
      @version = FactoryGirl.build(:version)
      @specification = gem_specification_from_gem_fixture('test-0.0.0')
      @specification.authors = [3]

      assert_raise ActiveRecord::RecordInvalid do
        @rubygem.update_versions!(@version, @specification)
      end

      assert_equal "Authors must be an Array of Strings", @rubygem.all_errors(@version)
    end

    should "return more than one error joined for #all_errors" do
      @specification = gem_specification_from_gem_fixture('test-0.0.0')
      @specification.homepage = "badurl.com"
      @rubygem.name = "1337"

      assert ! @rubygem.valid?
      assert_raise ActiveRecord::RecordInvalid do
        @rubygem.update_linkset!(@specification)
      end

      assert_match "Name must include at least one letter, Home does not appear to be a valid URL", @rubygem.all_errors
    end

    should "return dependency errors in #all_errors" do
      @version = Factory(:version, :rubygem => @rubygem)
      @specification = gem_specification_from_gem_fixture('test-0.0.0')
      @specification.add_runtime_dependency "limelight", "1.0.0"

      assert_raise ActiveRecord::RecordInvalid do
        @rubygem.update_dependencies!(@version, @specification)
      end
      assert_match "Please specify dependencies", @rubygem.all_errors(@version)
    end

    context "with a user" do
      setup do
        @user = Factory(:user)
        @rubygem.save
      end

      should "be able to assign ownership when no owners exist" do
        @rubygem.create_ownership(@user)
        assert_equal @rubygem.reload.owners, [@user]
      end

      should "not be able to assign ownership when owners exist" do
        @new_user = Factory(:user)
        @rubygem.ownerships.create(:user => @new_user)
        @rubygem.create_ownership(@user)
        assert_equal @rubygem.reload.owners, [@new_user]
      end
    end

    context "with a user" do
      setup do
        @rubygem.save
        @user = Factory(:user)
      end

      should "be owned by a user in ownership" do
        ownership = Factory(:ownership, :user => @user, :rubygem => @rubygem)
        assert @rubygem.owned_by?(@user)
        assert !@rubygem.unowned?
      end

      should "be not owned if no ownerships" do
        assert @rubygem.ownerships.empty?
        assert !@rubygem.owned_by?(@user)
        assert @rubygem.unowned?
      end

      should "be not owned if no user" do
        assert !@rubygem.owned_by?(nil)
        assert @rubygem.unowned?
      end
    end

    context "with subscribed users" do
      setup do
        @subscribed_user   = Factory(:user)
        @unsubscribed_user = Factory(:user)
        Factory(:subscription, :rubygem => @rubygem, :user => @subscribed_user)
      end

      should "only fetch the subscribed users with #subscribers" do
        assert_contains         @rubygem.subscribers, @subscribed_user
        assert_does_not_contain @rubygem.subscribers, @unsubscribed_user
      end
    end

    should "return current version" do
      assert_equal @rubygem.versions.first, @rubygem.versions.most_recent
    end

    should "return name with version for #to_s" do
      @rubygem.save
      Factory(:version, :number => "0.0.0", :rubygem => @rubygem)
      assert_equal "#{@rubygem.name} (#{@rubygem.versions.most_recent})", @rubygem.to_s
    end

    should "return name for #to_s if current version doesn't exist" do
      assert_equal @rubygem.name, @rubygem.to_s
    end

    should "return name with downloads for #with_downloads" do
      assert_equal "#{@rubygem.name} (#{@rubygem.downloads})", @rubygem.with_downloads
    end

    should "return a bunch of json" do
      version = Factory(:version, :rubygem => @rubygem)
      run_dep = Factory(:runtime_dependency, :version => version)
      dev_dep = Factory(:development_dependency, :version => version)

      hash = JSON.parse(@rubygem.to_json)

      assert_equal @rubygem.name, hash["name"]
      assert_equal @rubygem.downloads, hash["downloads"]
      assert_equal @rubygem.versions.most_recent.number, hash["version"]
      assert_equal @rubygem.versions.most_recent.downloads_count, hash["version_downloads"]
      assert_equal @rubygem.versions.most_recent.authors, hash["authors"]
      assert_equal @rubygem.versions.most_recent.info, hash["info"]
      assert_equal "http://#{HOST}/gems/#{@rubygem.name}", hash["project_uri"]
      assert_equal "http://#{HOST}/gems/#{@rubygem.versions.most_recent.full_name}.gem", hash["gem_uri"]

      assert_equal JSON.parse(dev_dep.to_json), hash["dependencies"]["development"].first
      assert_equal JSON.parse(run_dep.to_json), hash["dependencies"]["runtime"].first
    end

    should "return a bunch of xml" do
      version = Factory(:version, :rubygem => @rubygem)
      run_dep = Factory(:runtime_dependency, :version => version)
      dev_dep = Factory(:development_dependency, :version => version)

      doc = Nokogiri.parse(@rubygem.to_xml)

      assert_equal "rubygem", doc.root.name
      assert_equal @rubygem.name, doc.at_css("rubygem > name").content
      assert_equal @rubygem.downloads.to_s, doc.at_css("downloads").content
      assert_equal @rubygem.versions.most_recent.number, doc.at_css("version").content
      assert_equal @rubygem.versions.most_recent.downloads_count.to_s, doc.at_css("version-downloads").content
      assert_equal @rubygem.versions.most_recent.authors, doc.at_css("authors").content
      assert_equal @rubygem.versions.most_recent.info, doc.at_css("info").content
      assert_equal "http://#{HOST}/gems/#{@rubygem.name}", doc.at_css("project-uri").content
      assert_equal "http://#{HOST}/gems/#{@rubygem.versions.most_recent.full_name}.gem", doc.at_css("gem-uri").content

      assert_equal dev_dep.name, doc.at_css("dependencies development dependency name").content
      assert_equal run_dep.name, doc.at_css("dependencies runtime dependency name").content
    end

    context "with a linkset" do
      setup do
        @rubygem = FactoryGirl.build(:rubygem)
        version = Factory(:version, :rubygem => @rubygem)
      end

      should "return a bunch of JSON" do
        hash = JSON.parse(@rubygem.to_json)

        assert_equal @rubygem.linkset.home, hash["homepage_uri"]
        assert_equal @rubygem.linkset.wiki, hash["wiki_uri"]
        assert_equal @rubygem.linkset.docs, hash["documentation_uri"]
        assert_equal @rubygem.linkset.mail, hash["mailing_list_uri"]
        assert_equal @rubygem.linkset.code, hash["source_code_uri"]
        assert_equal @rubygem.linkset.bugs, hash["bug_tracker_uri"]
      end

      should "return a bunch of XML" do
        doc = Nokogiri.parse(@rubygem.to_xml)

        assert_equal @rubygem.linkset.home, doc.at_css("homepage-uri").content
        assert_equal @rubygem.linkset.wiki, doc.at_css("wiki-uri").content
        assert_equal @rubygem.linkset.docs, doc.at_css("documentation-uri").content
        assert_equal @rubygem.linkset.mail, doc.at_css("mailing-list-uri").content
        assert_equal @rubygem.linkset.code, doc.at_css("source-code-uri").content
        assert_equal @rubygem.linkset.bugs, doc.at_css("bug-tracker-uri").content
      end
    end
  end

  context "with some rubygems" do
    setup do
      @rubygem_without_version = Factory(:rubygem)
      @rubygem_with_version = Factory(:rubygem)
      @rubygem_with_versions = Factory(:rubygem)

      Factory(:version, :rubygem => @rubygem_with_version)
      3.times { Factory(:version, :rubygem => @rubygem_with_versions) }

      @owner = Factory(:user)
      Factory(:ownership, :rubygem => @rubygem_with_version, :user => @owner)
      Factory(:ownership, :rubygem => @rubygem_with_versions, :user => @owner)
    end

    should "return only gems with one version" do
      assert ! Rubygem.with_one_version.include?(@rubygem_without_version)
      assert Rubygem.with_one_version.include?(@rubygem_with_version)
      assert ! Rubygem.with_one_version.include?(@rubygem_with_versions)
    end

    should "return only gems with versions for #with_versions" do
      assert ! Rubygem.with_versions.include?(@rubygem_without_version)
      assert Rubygem.with_versions.include?(@rubygem_with_version)
      assert Rubygem.with_versions.include?(@rubygem_with_versions)
    end

    should "be hosted or not" do
      assert ! @rubygem_without_version.hosted?
      assert @rubygem_with_version.hosted?
    end

    context "when yanking the last version of a gem with an owner" do
      setup do
        @rubygem_with_version.yank!(@rubygem_with_version.versions.first)
      end

      should "no longer be owned" do
        assert @rubygem_with_version.reload.unowned?
      end
    end

    context "when yanking one of many versions of a gem" do
      setup do
        @rubygem_with_versions.yank!(@rubygem_with_versions.versions.first)
      end
      should "remain owned" do
        assert !@rubygem_with_versions.reload.unowned?
      end
    end
  end

  context "with some gems and some that don't have versions" do
    setup do
      @thin = Factory(:rubygem, :name => 'thin', :created_at => 1.year.ago,  :downloads => 20)
      @rake = Factory(:rubygem, :name => 'rake', :created_at => 1.month.ago, :downloads => 10)
      @json = Factory(:rubygem, :name => 'json', :created_at => 1.week.ago,  :downloads => 5)
      @thor = Factory(:rubygem, :name => 'thor', :created_at => 2.days.ago,  :downloads => 3)
      @rack = Factory(:rubygem, :name => 'rack', :created_at => 1.day.ago,   :downloads => 2)
      @dust = Factory(:rubygem, :name => 'dust', :created_at => 3.days.ago,  :downloads => 1)
      @haml = Factory(:rubygem, :name => 'haml')
      @new = FactoryGirl.build(:rubygem)

      @gems = [@thin, @rake, @json, @thor, @rack, @dust]
      @gems.each { |g| Factory(:version, :rubygem => g) }
    end

    should "be pushable if gem is a new record" do
      assert @new.pushable?
    end

    should "be pushable if gem has no versions" do
      assert @haml.pushable?
    end

    should "not be pushable if it has versions" do
      assert ! @thin.pushable?
    end

    should "give a count of only rubygems with versions" do
      assert_equal 6, Rubygem.total_count
    end

    should "only return the latest gems with versions" do
      assert_equal [@rack, @thor, @dust, @json, @rake],        Rubygem.latest
      assert_equal [@rack, @thor, @dust, @json, @rake, @thin], Rubygem.latest(6)
    end

    should "only latest downloaded versions" do
      assert_equal [@thin, @rake, @json, @thor, @rack],        Rubygem.downloaded
      assert_equal [@thin, @rake, @json, @thor, @rack, @dust], Rubygem.downloaded(6)
    end
  end

  context "when some gems exist with titles and versions that have descriptions" do
    setup do
      @apple_pie = Factory(:rubygem, :name => 'apple', :downloads => 1)
      Factory(:version, :description => 'pie', :rubygem => @apple_pie)

      @apple_crisp = Factory(:rubygem, :name => 'apple_crisp', :downloads => 10)
      Factory(:version, :description => 'pie', :rubygem => @apple_crisp)

      @orange_julius = Factory(:rubygem, :name => 'orange')
      Factory(:version, :description => 'julius', :rubygem => @orange_julius)
    end

    should "find rubygems by name on #search" do
      assert Rubygem.search('apple').include?(@apple_pie)
      assert Rubygem.search('orange').include?(@orange_julius)

      assert ! Rubygem.search('apple').include?(@orange_julius)
      assert ! Rubygem.search('orange').include?(@apple_pie)
    end

    should "find rubygems by name with extra spaces on #search" do
      assert Rubygem.search('apple  ').include?(@apple_pie)
      assert Rubygem.search('orange   ').include?(@orange_julius)
      assert_equal Rubygem.search('apple'), Rubygem.search('apple ')

      assert ! Rubygem.search('apple  ').include?(@orange_julius)
      assert ! Rubygem.search('orange   ').include?(@apple_pie)
    end

    should "find rubygems by description on #search" do
      assert Rubygem.search('pie').include?(@apple_pie)
      assert Rubygem.search('julius').include?(@orange_julius)

      assert ! Rubygem.search('pie').include?(@orange_julius)
      assert ! Rubygem.search('julius').include?(@apple_pie)
    end

    should "find rubygems case insensitively on #search" do
      assert Rubygem.search('APPLE').include?(@apple_pie)
      assert Rubygem.search('PIE').include?(@apple_pie)
    end

    should "find rubygems with missing punctuation on #search" do
      assert Rubygem.search('apple crisp').include?(@apple_crisp)
      assert ! Rubygem.search('apple crisp').include?(@apple_pie)
    end

    should "sort results by number of downloads, descending" do
      assert_equal [@apple_crisp, @apple_pie], Rubygem.search('apple')
    end

    should "find exact match by name on #name_is" do
      assert_equal @apple_crisp, Rubygem.name_is('apple_crisp').first
    end

    should "find exact match by name with extra spaces on #name_is" do
      assert_equal @apple_crisp, Rubygem.name_is('apple_crisp ').first
    end
  end

  context "building a new Rubygem" do
    context "from a Gem::Specification with no dependencies" do
      setup do
        @specification = gem_specification_from_gem_fixture('test-0.0.0')
        @rubygem       = Rubygem.new(:name => @specification.name)
        @version       = @rubygem.find_or_initialize_version_from_spec(@specification)
        @rubygem.update_attributes_from_gem_specification!(@version, @specification)
      end

      should "create a rubygem and associated records" do
        assert ! @rubygem.new_record?
        assert @rubygem.versions.present?
      end

      should "have the homepage set properly" do
        assert_equal @specification.homepage, @rubygem.linkset.home
      end
    end

    context "from a Gem::Specification with bad dependencies" do
      setup do
        @specification = gem_specification_from_gem_fixture('with_dependencies-0.0.0')
        @rubygem       = Rubygem.new(:name => @specification.name)
        @version       = @rubygem.find_or_initialize_version_from_spec(@specification)
      end

      should "raise invalid error" do
        assert_raise ActiveRecord::RecordInvalid do
          @rubygem.update_attributes_from_gem_specification!(@version, @specification)
        end

        assert_nil Rubygem.find_by_name('with_dependencies')
        assert_nil Rubygem.find_by_name('thoughtbot-shoulda')
        assert_nil Rubygem.find_by_name('rake')
      end
    end

    context "from a Gem::Specification with pre-existing dependencies" do
      setup do
        @specification = gem_specification_from_gem_fixture('with_dependencies-0.0.0')
        Rubygem.create(:name => "thoughtbot-shoulda")
        Rubygem.create(:name => "rake")

        @rubygem       = Rubygem.new(:name => @specification.name)
        @version       = @rubygem.find_or_initialize_version_from_spec(@specification)
      end

      should "save the gem" do
        assert_nothing_raised do
          @rubygem.update_attributes_from_gem_specification!(@version, @specification)
        end

        assert ! @rubygem.new_record?
        assert ! @version.new_record?
        assert_equal 1, @rubygem.versions.count
        assert_equal 2, @version.dependencies.count
        assert Rubygem.exists?(:name => 'thoughtbot-shoulda')
        assert Rubygem.exists?(:name => 'rake')
      end
    end
  end

  context "downloads" do
    setup do
      @rubygem = Factory(:rubygem)
      @version = Factory(:version, :rubygem => @rubygem)

      Timecop.freeze DateTime.parse("2010-10-02")
      1.times { Download.incr(@rubygem.name, @version.full_name) }
      Download.rollover

      Timecop.freeze DateTime.parse("2010-10-03")
      6.times { Download.incr(@rubygem.name, @version.full_name) }
      Download.rollover

      Timecop.freeze DateTime.parse("2010-10-16")
      4.times { Download.incr(@rubygem.name, @version.full_name) }
      Download.rollover

      Timecop.freeze DateTime.parse("2010-11-01")
      2.times { Download.incr(@rubygem.name, @version.full_name) }
      Download.rollover

      Timecop.freeze DateTime.parse("2010-11-02")
    end

    should "give counts from the past 30 days" do
      downloads = @rubygem.monthly_downloads

      assert_equal 30, downloads.size
      assert_equal 6, downloads.first
      (3..14).each do |n|
        assert_equal 0, downloads[n.to_i - 2]
      end
      assert_equal 4, downloads[13]
      (16..30).each do |n|
        assert_equal 0, downloads[n.to_i - 2]
      end
      assert_equal 2, downloads.last
    end

    should "give the monthly dates back" do
      assert_equal ("02".."31").map { |date| "10/#{date}" }, Rubygem.monthly_short_dates
    end

    teardown do
      Timecop.return
    end
  end
end
