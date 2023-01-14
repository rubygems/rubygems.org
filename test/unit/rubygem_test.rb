require "test_helper"

class RubygemTest < ActiveSupport::TestCase
  context "with a saved rubygem" do
    setup do
      @rubygem = Rubygem.new(name: "SomeGem")
    end
    subject { @rubygem }

    should have_many(:owners).through(:ownerships)
    should have_many(:ownerships).dependent(:destroy)
    should have_many(:subscribers).through(:subscriptions)
    should have_many(:subscriptions).dependent(:destroy)
    should have_many(:versions).dependent(:destroy)
    should have_many(:web_hooks).dependent(:destroy)
    should have_one(:linkset).dependent(:destroy)
    should validate_uniqueness_of(:name).case_insensitive
    should allow_value("rails").for(:name)
    should allow_value("awesome42").for(:name)
    should allow_value("factory_girl").for(:name)
    should allow_value("rack-test").for(:name)
    should allow_value("perftools.rb").for(:name)
    should_not allow_value("\342\230\203").for(:name)
    should_not allow_value("2.2").for(:name)
    should_not allow_value("Ruby").for(:name)
    should_not allow_value(".omghi").for(:name)
    should_not allow_value("-omghi").for(:name)
    should_not allow_value("_omghi").for(:name)

    context "that has an invalid name already persisted" do
      setup do
        subject.save!
        subject.update_column(:name, "_")
      end

      should "consider the gem valid" do
        assert_predicate subject, :valid?
      end
    end

    should "be invalid with name longer than maximum field length" do
      @rubygem.name = "r" * (Gemcutter::MAX_FIELD_LENGTH + 1)
      refute_predicate @rubygem, :valid?
      assert_equal(["is too long (maximum is 255 characters)"], @rubygem.errors.messages[:name])
    end

    should "reorder versions with platforms properly" do
      version3_ruby  = create(:version, rubygem: @rubygem, number: "3.0.0", platform: "ruby")
      version3_mswin = create(:version, rubygem: @rubygem, number: "3.0.0", platform: "mswin")
      version2_ruby  = create(:version, rubygem: @rubygem, number: "2.0.0", platform: "ruby")
      version1_linux = create(:version, rubygem: @rubygem, number: "1.0.0", platform: "linux")

      @rubygem.reorder_versions

      assert_equal 0, version3_ruby.reload.position
      assert_equal 0, version3_mswin.reload.position
      assert_equal 1, version2_ruby.reload.position
      assert_equal 2, version1_linux.reload.position

      latest_versions = Version.latest
      assert_includes latest_versions, version3_ruby
      assert_includes latest_versions, version3_mswin

      assert_equal version3_ruby, @rubygem.versions.most_recent
    end

    should "order latest platform gems with latest uniquely" do
      pre  = create(:version,
        rubygem: @rubygem,
        number: "1.5.0.pre",
        platform: "ruby",
        prerelease: true)
      ming = create(:version,
        rubygem: @rubygem,
        number: "1.4.2.1",
        platform: "x86-mingw32")
      win = create(:version,
        rubygem: @rubygem,
        number: "1.4.2.1",
        platform: "x86-mswin32")
      ruby = create(:version,
        rubygem: @rubygem,
        number: "1.4.2",
        platform: "ruby")
      java = create(:version,
        rubygem: @rubygem,
        number: "1.4.2",
        platform: "java")
      old = create(:version,
        rubygem: @rubygem,
        number: "1.4.1",
        platform: "ruby")

      @rubygem.reorder_versions

      refute pre.reload.latest
      refute old.reload.latest
      assert ming.reload.latest
      assert win.reload.latest
      assert ruby.reload.latest
      assert java.reload.latest
    end

    should "not return platform gem for latest if the ruby version is old" do
      version3_mswin = create(:version, rubygem: @rubygem, number: "3.0.0", platform: "mswin")
      version2_ruby  = create(:version, rubygem: @rubygem, number: "2.0.0", platform: "ruby")

      @rubygem.reorder_versions

      assert_equal version2_ruby.reload, @rubygem.versions.most_recent
      assert version3_mswin.reload.latest
    end

    should "not have a most recent version if no versions exist" do
      assert_nil @rubygem.versions.most_recent
    end

    should "return the ruby version for most_recent if one exists" do
      create(:version,
        rubygem: @rubygem,
        number: "3.0.0",
        platform: "mswin",
        built_at: 1.year.from_now)
      version3_ruby = create(:version, rubygem: @rubygem, number: "3.0.0", platform: "ruby")

      @rubygem.reorder_versions

      assert_equal version3_ruby, @rubygem.versions.most_recent
    end

    should "have a most_recent version if only a platform version exists" do
      version1 = create(:version, rubygem: @rubygem, number: "1.0.0", platform: "linux")

      assert_equal version1, @rubygem.reload.versions.most_recent
    end

    should "return the release version for most_recent if one exists" do
      create(:version, rubygem: @rubygem, number: "2.0.pre", platform: "ruby")
      version1 = create(:version, rubygem: @rubygem, number: "1.0.0", platform: "ruby")

      assert_equal version1, @rubygem.reload.versions.most_recent
    end

    should "have a most_recent version if only a prerelease version exists" do
      version1pre = create(:version, rubygem: @rubygem, number: "1.0.pre", platform: "ruby")

      assert_equal version1pre, @rubygem.reload.versions.most_recent
    end

    should "return the most_recent indexed version when a more recent yanked version exists" do
      create(:version, rubygem: @rubygem, number: "0.1.1", indexed: false)
      indexed_v1 = create(:version, rubygem: @rubygem, number: "0.1.0", indexed: true)

      assert_equal indexed_v1.reload, @rubygem.reload.versions.most_recent
    end

    should "return latest version on the basis of version number" do
      version = create(:version, rubygem: @rubygem, number: "0.1.1", platform: "ruby", latest: true)
      create(:version, rubygem: @rubygem, number: "0.1.2.rc1", platform: "ruby")
      create(:version, rubygem: @rubygem, number: "0.1.0", platform: "jruby", latest: true)

      assert_equal version, @rubygem.latest_version
    end

    context "#public_versions_with_extra_version" do
      setup do
        @first_version = FactoryBot.create(:version,
          rubygem: @rubygem,
          number: "1.0.0",
          position: 1)
        @extra_version = FactoryBot.create(:version,
          rubygem: @rubygem,
          number: "0.1.0",
          position: 2)
      end
      should "include public versions" do
        assert_includes @rubygem.public_versions_with_extra_version(@extra_version), @first_version
      end
      should "include extra version" do
        assert_includes @rubygem.public_versions_with_extra_version(@extra_version), @extra_version
      end
      should "maintain proper ordering" do
        versions = @rubygem.public_versions_with_extra_version(@extra_version)
        assert_equal versions, versions.sort_by(&:position)
      end
      should "not duplicate versions" do
        versions = @rubygem.public_versions_with_extra_version(@first_version)
        assert_equal versions.count, versions.uniq.count
      end
    end

    should "update references in dependencies when destroyed" do
      @rubygem.save!
      dependency = create(:dependency, rubygem: @rubygem)

      @rubygem.destroy

      dependency.reload
      assert_nil dependency.rubygem_id
      assert_equal dependency.unresolved_name, @rubygem.name
    end
  end

  context "with reverse dependencies" do
    setup do
      @dependency            = create(:rubygem)
      @gem_one               = create(:rubygem)
      @gem_two               = create(:rubygem)
      gem_three              = create(:rubygem)
      gem_four               = create(:rubygem)
      version_one            = create(:version, rubygem: @gem_one)
      version_two            = create(:version, rubygem: @gem_two)
      _version_three_latest  = create(:version, rubygem: gem_three, number: "1.0")
      version_three_earlier  = create(:version, rubygem: gem_three, number: "0.5")
      yanked_version         = create(:version, :yanked, rubygem: gem_four)

      create(:dependency, :runtime, version: version_one, rubygem: @dependency)
      create(:dependency, :development, version: version_two, rubygem: @dependency)
      create(:dependency, version: version_three_earlier, rubygem: @dependency)
      create(:dependency, version: yanked_version, rubygem: @dependency)
    end

    context "#reverse_dependencies" do
      should "return dependent gems of latest indexed version" do
        gem_list = @dependency.reverse_dependencies

        assert_equal 2, gem_list.size

        assert_includes gem_list, @gem_one
        assert_includes gem_list, @gem_two
        refute_includes gem_list, @gem_three
        refute_includes gem_list, @gem_four
      end
    end

    context "#reverse_runtime_dependencies" do
      should "return runtime dependent rubygems" do
        gem_list = @dependency.reverse_runtime_dependencies
        assert_equal 1, gem_list.size

        assert_includes gem_list, @gem_one
        refute_includes gem_list, @gem_two
      end
    end

    context "#reverse_development_dependencies" do
      should "return development dependent rubygems" do
        gem_list = @dependency.reverse_development_dependencies
        assert_equal 1, gem_list.size

        assert_includes gem_list, @gem_two
        refute_includes gem_list, @gem_one
      end
    end
  end

  context "with a rubygem" do
    setup do
      @rubygem = build(:rubygem, linkset: nil)
    end

    ["1337", "Snakes!"].each do |bad_name|
      should "not accept #{bad_name.inspect} as a name" do
        @rubygem.name = bad_name
        refute_predicate @rubygem, :valid?
        assert_match(/Name/, @rubygem.all_errors)
      end
    end

    should "not accept an Array as name" do
      @rubygem.name = ["zomg"]
      refute_predicate @rubygem, :valid?
    end

    should "return linkset errors in #all_errors" do
      @specification = gem_specification_from_gem_fixture("test-0.0.0")
      @specification.homepage = "badurl.com"

      assert_raise ActiveRecord::RecordInvalid do
        @rubygem.update_linkset!(@specification)
      end

      assert_equal "Home does not appear to be a valid URL", @rubygem.all_errors
    end

    should "return version errors in #all_errors" do
      @version = build(:version)
      @specification = gem_specification_from_gem_fixture("test-0.0.0")
      @specification.authors = [3]

      assert_raise ActiveRecord::RecordInvalid do
        @rubygem.update_versions!(@version, @specification)
      end

      assert_equal "Authors must be an Array of Strings", @rubygem.all_errors(@version)
    end

    should "return array of author names in #authors_array" do
      @version = build(:version)
      assert_equal ["Joe User"], @version.authors_array
    end

    should "return more than one error joined for #all_errors" do
      @specification = gem_specification_from_gem_fixture("test-0.0.0")
      @specification.homepage = "badurl.com"
      @rubygem.name = "1337"

      refute_predicate @rubygem, :valid?
      assert_raise ActiveRecord::RecordInvalid do
        @rubygem.update_linkset!(@specification)
      end

      assert_match "Name must include at least one letter, Home does not appear to be a valid URL",
        @rubygem.all_errors
    end

    context "with a user" do
      setup do
        @user = create(:user)
        @rubygem.save
      end

      should "be able to assign ownership when no owners exist" do
        @rubygem.create_ownership(@user)
        assert_equal @rubygem.reload.owners, [@user]
      end

      should "not be able to assign ownership when owners exist" do
        @new_user = create(:user)
        create(:ownership, rubygem: @rubygem, user: @new_user)
        @rubygem.create_ownership(@user)
        assert_equal @rubygem.reload.owners, [@new_user]
      end
    end

    context "with a user" do
      setup do
        @rubygem.save
        @user = create(:user)
      end

      should "be owned by a user in ownership" do
        create(:ownership, user: @user, rubygem: @rubygem)
        assert @rubygem.owned_by?(@user)
        refute_predicate @rubygem, :unowned?
      end

      should "be not owned if no ownerships" do
        assert_empty @rubygem.ownerships
        refute @rubygem.owned_by?(@user)
        assert_predicate @rubygem, :unowned?
      end

      should "be not owned if no user" do
        refute @rubygem.owned_by?(nil)
        assert_predicate @rubygem, :unowned?
      end
    end

    context "with subscribed users" do
      setup do
        @subscribed_user   = create(:user)
        @unsubscribed_user = create(:user)
        create(:subscription, rubygem: @rubygem, user: @subscribed_user)
      end

      should "only fetch the subscribed users with #subscribers" do
        assert_contains @rubygem.subscribers, @subscribed_user
        assert_does_not_contain @rubygem.subscribers, @unsubscribed_user
      end
    end

    should "return name with version for #to_s" do
      @rubygem.save
      create(:version, number: "0.0.0", rubygem: @rubygem)
      assert_equal "#{@rubygem.name} (#{@rubygem.versions.most_recent})", @rubygem.to_s
    end

    should "return name for #to_s if current version doesn't exist" do
      assert_equal @rubygem.name, @rubygem.to_s
    end

    should "return name as slug with only allowed characters" do
      @rubygem.name = "rails?!"
      assert_equal "rails", @rubygem.to_param
    end

    should "return a bunch of json" do
      version = create(:version, rubygem: @rubygem)
      run_dep = create(:dependency, :runtime, version: version)
      dev_dep = create(:dependency, :development, version: version)

      hash = JSON.load(@rubygem.to_json)

      assert_equal @rubygem.name, hash["name"]
      assert_equal @rubygem.downloads, hash["downloads"]
      assert_equal @rubygem.versions.most_recent.number, hash["version"]
      assert_equal @rubygem.versions.most_recent.created_at.as_json, hash["version_created_at"]
      assert_equal @rubygem.versions.most_recent.downloads_count, hash["version_downloads"]
      assert_equal @rubygem.versions.most_recent.platform, hash["platform"]
      assert_equal @rubygem.versions.most_recent.authors, hash["authors"]
      assert_equal @rubygem.versions.most_recent.info, hash["info"]
      assert_equal @rubygem.versions.most_recent.metadata, hash["metadata"]
      assert_equal "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}/gems/#{@rubygem.name}",
        hash["project_uri"]
      assert_equal "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}/gems/" \
                   "#{@rubygem.versions.most_recent.full_name}.gem", hash["gem_uri"]

      assert_equal JSON.load(dev_dep.to_json), hash["dependencies"]["development"].first
      assert_equal JSON.load(run_dep.to_json), hash["dependencies"]["runtime"].first
    end

    should "return a bunch of xml" do
      version = create(:version, rubygem: @rubygem)
      run_dep = create(:dependency, :runtime, version: version)
      dev_dep = create(:dependency, :development, version: version)

      doc = Nokogiri.parse(@rubygem.to_xml)

      assert_equal "rubygem",
        doc.root.name
      assert_equal @rubygem.name,
        doc.at_css("rubygem > name").content
      assert_equal @rubygem.downloads.to_s,
        doc.at_css("downloads").content
      assert_equal @rubygem.versions.most_recent.number,
        doc.at_css("version").content
      assert_equal @rubygem.versions.most_recent.downloads_count.to_s,
        doc.at_css("version-downloads").content
      assert_equal @rubygem.versions.most_recent.authors,
        doc.at_css("authors").content
      assert_equal @rubygem.versions.most_recent.info,
        doc.at_css("info").content
      assert_equal @rubygem.versions.most_recent.metadata["foo"],
        doc.at_css("metadata foo").content
      assert_equal @rubygem.versions.most_recent.sha256_hex,
        doc.at_css("sha").content
      assert_equal "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}/gems/#{@rubygem.name}",
        doc.at_css("project-uri").content
      assert_equal "#{Gemcutter::PROTOCOL}://#{Gemcutter::HOST}/gems/" \
                   "#{@rubygem.versions.most_recent.full_name}.gem", doc.at_css("gem-uri").content

      assert_equal dev_dep.name, doc.at_css("dependencies development dependency name").content
      assert_equal run_dep.name, doc.at_css("dependencies runtime dependency name").content
    end

    context "with metadata" do
      setup do
        @rubygem.linkset = build(:linkset)
        @version = create(:version, rubygem: @rubygem)
      end

      should "prefer metadata over links in JSON" do
        @version.update!(
          metadata: {
            "homepage_uri" => "http://example.com/home",
            "wiki_uri" => "http://example.com/wiki",
            "documentation_uri" => "http://example.com/docs",
            "mailing_list_uri" => "http://example.com/mail",
            "source_code_uri" => "http://example.com/code",
            "bug_tracker_uri" => "http://example.com/bugs",
            "changelog_uri" => "http://example.com/change",
            "funding_uri" => "http://example.com/funding"
          }
        )

        hash = MultiJson.load(@rubygem.to_json)

        assert_equal "http://example.com/home", hash["homepage_uri"]
        assert_equal "http://example.com/wiki", hash["wiki_uri"]
        assert_equal "http://example.com/docs", hash["documentation_uri"]
        assert_equal "http://example.com/mail", hash["mailing_list_uri"]
        assert_equal "http://example.com/code", hash["source_code_uri"]
        assert_equal "http://example.com/bugs", hash["bug_tracker_uri"]
        assert_equal "http://example.com/change", hash["changelog_uri"]
        assert_equal "http://example.com/funding", hash["funding_uri"]
      end

      should "return version documentation url if metadata and linkset docs is empty" do
        @version.update!(metadata: {})
        @rubygem.linkset.update_attribute(:docs, "")

        hash = JSON.load(@rubygem.to_json)

        assert_equal "https://www.rubydoc.info/gems/#{@rubygem.name}/#{@version.number}", hash["documentation_uri"]
      end
    end

    context "with a linkset" do
      setup do
        @rubygem = build(:rubygem)
        @version = create(:version, rubygem: @rubygem)
      end

      should "return a bunch of JSON" do
        hash = JSON.load(@rubygem.to_json)

        assert_equal @rubygem.linkset.home, hash["homepage_uri"]
        assert_equal @rubygem.linkset.wiki, hash["wiki_uri"]
        assert_equal @rubygem.linkset.docs, hash["documentation_uri"]
        assert_equal @rubygem.linkset.mail, hash["mailing_list_uri"]
        assert_equal @rubygem.linkset.code, hash["source_code_uri"]
        assert_equal @rubygem.linkset.bugs, hash["bug_tracker_uri"]
      end

      should "return version documentation uri if linkset docs is empty" do
        @rubygem.linkset.docs = ""
        hash = JSON.load(@rubygem.to_json)

        assert_equal "https://www.rubydoc.info/gems/#{@rubygem.name}/#{@version.number}", hash["documentation_uri"]
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
      @rubygem_without_version = create(:rubygem)
      @rubygem_with_version = create(:rubygem)
      @rubygem_with_versions = create(:rubygem)

      create(:version, rubygem: @rubygem_with_version)
      3.times { create(:version, rubygem: @rubygem_with_versions) }

      @owner = create(:user)
      create(:ownership, rubygem: @rubygem_with_version, user: @owner)
      create(:ownership, rubygem: @rubygem_with_versions, user: @owner)
    end

    should "return only gems with one version" do
      refute_includes Rubygem.with_one_version, @rubygem_without_version
      assert_includes Rubygem.with_one_version, @rubygem_with_version
      refute_includes Rubygem.with_one_version, @rubygem_with_versions
    end

    should "return only gems with versions for #with_versions" do
      refute_includes Rubygem.with_versions, @rubygem_without_version
      assert_includes Rubygem.with_versions, @rubygem_with_version
      assert_includes Rubygem.with_versions, @rubygem_with_versions
    end

    should "be hosted or not" do
      refute_predicate @rubygem_without_version, :hosted?
      assert_predicate @rubygem_with_version, :hosted?
    end

    context "when yanking the last version of a gem with an owner" do
      setup do
        @rubygem_with_version.versions.first.update! indexed: false
      end

      should "still be owned" do
        assert @rubygem_with_version.owned_by?(@owner)
      end

      should "no longer be indexed" do
        assert_predicate @rubygem_with_version.versions.indexed.count, :zero?
      end
    end

    context "when yanking one of many versions of a gem" do
      setup do
        @rubygem_with_versions.versions.first.update! indexed: false
      end
      should "remain owned" do
        refute_predicate @rubygem_with_versions.reload, :unowned?
      end
      should "then know there is a yanked version" do
        assert_predicate @rubygem_with_versions, :yanked_versions?
      end
    end
  end

  context "with some gems and some that don't have versions" do
    setup do
      @thin = create(:rubygem, name: "thin", created_at: 1.year.ago,  downloads: 20)
      @rake = create(:rubygem, name: "rake", created_at: 1.month.ago, downloads: 10)
      @json = create(:rubygem, name: "json", created_at: 1.week.ago,  downloads: 5)
      @thor = create(:rubygem, name: "thor", created_at: 2.days.ago,  downloads: 3)
      @rack = create(:rubygem, name: "rack", created_at: 1.day.ago,   downloads: 2)
      @dust = create(:rubygem, name: "dust", created_at: 3.days.ago,  downloads: 1)
      @haml = create(:rubygem, name: "haml")
      @new = build(:rubygem)

      @gems = [@thin, @rake, @json, @thor, @rack, @dust]
      @gems.each { |g| create(:version, rubygem: g) }
    end

    should "be pushable if gem is a new record" do
      assert_predicate @new, :pushable?
    end

    context "gem has no versions" do
      should "be pushable if gem is less than one month old" do
        assert_predicate @haml, :pushable?
      end

      should "be pushable if gem was yanked more than 100 days ago" do
        @haml.update(created_at: 101.days.ago, updated_at: 101.days.ago)
        assert_predicate @haml, :pushable?
      end

      should "not be pushable if gem is older than a month and yanked less than 100 days ago" do
        @haml.update(created_at: 99.days.ago, updated_at: 99.days.ago)
        refute_predicate @haml, :pushable?
      end
    end

    should "not be pushable if it has versions" do
      refute_predicate @thin, :pushable?
    end

    should "only return the latest gems with versions" do
      assert_equal [@rack, @thor, @dust, @json, @rake],        Rubygem.latest
      assert_equal [@rack, @thor, @dust, @json, @rake, @thin], Rubygem.latest(6)
    end

    should "only latest downloaded versions" do
      assert_equal [@thin, @rake, @json, @thor, @rack],        Rubygem.downloaded
      assert_equal [@thin, @rake, @json, @thor, @rack, @dust], Rubygem.downloaded(6)
    end

    context ".total_count" do
      setup { @expected_total = 6 }

      should "give a count of only rubygems with versions" do
        assert_equal @expected_total, Rubygem.total_count
      end
    end
  end

  context "when some gems exist with titles and versions" do
    setup do
      @apple_pie = create(:rubygem, name: "apple", downloads: 1)
      create(:version, description: "pie", rubygem: @apple_pie)

      @apple_crisp = create(:rubygem, name: "apple_crisp", downloads: 10)
      create(:version, description: "pie", rubygem: @apple_crisp)

      @orange_julius = create(:rubygem, name: "orange")
      create(:version, description: "julius", rubygem: @orange_julius)
    end

    context "#legacy_search" do
      should "find rubygems by name" do
        assert_includes Rubygem.legacy_search("apple"), @apple_pie
        assert_includes Rubygem.legacy_search("orange"), @orange_julius

        refute_includes Rubygem.legacy_search("apple"), @orange_julius
        refute_includes Rubygem.legacy_search("orange"), @apple_pie
      end

      should "find rubygems by name with extra spaces" do
        assert_includes Rubygem.legacy_search("apple  "), @apple_pie
        assert_includes Rubygem.legacy_search("orange   "), @orange_julius
        assert_equal Rubygem.legacy_search("apple"), Rubygem.legacy_search("apple ")

        refute_includes Rubygem.legacy_search("apple  "), @orange_julius
        refute_includes Rubygem.legacy_search("orange   "), @apple_pie
      end

      should "find rubygems case insensitively" do
        assert_includes Rubygem.legacy_search("APPLE"), @apple_pie
      end

      should "find rubygems with missing punctuation" do
        assert_includes Rubygem.legacy_search("apple crisp"), @apple_crisp
        refute_includes Rubygem.legacy_search("apple crisp"), @apple_pie
      end

      should "sort results by number of downloads, descending" do
        assert_equal [@apple_crisp, @apple_pie], Rubygem.legacy_search("apple")
      end
    end

    should "find exact match by name on #name_is" do
      assert_equal @apple_crisp, Rubygem.name_is("apple_crisp").first
    end

    should "find exact match by name with extra spaces on #name_is" do
      assert_equal @apple_crisp, Rubygem.name_is("apple_crisp ").first
    end
  end

  context "building a new Rubygem" do
    context "from a Gem::Specification with no dependencies" do
      setup do
        @specification = gem_specification_from_gem_fixture("test-0.0.0")
        @rubygem       = Rubygem.new(name: @specification.name)
        @version       = @rubygem.find_or_initialize_version_from_spec(@specification)
        @version.sha256 = "dummy"
        @rubygem.update_attributes_from_gem_specification!(@version, @specification)
      end

      should "create a rubygem and associated records" do
        refute_predicate @rubygem, :new_record?
        assert_predicate @rubygem.versions, :present?
      end

      should "have the homepage set properly" do
        assert_equal @specification.homepage, @rubygem.linkset.home
      end
    end

    context "from a Gem::Specification with dependencies on unknown gems" do
      setup do
        @specification = gem_specification_from_gem_fixture("with_dependencies-0.0.0")
        @rubygem       = Rubygem.new(name: @specification.name)
        @version       = @rubygem.find_or_initialize_version_from_spec(@specification)
        @version.sha256 = "dummy"
      end

      should "save the gem" do
        @rubygem.update_attributes_from_gem_specification!(@version, @specification)

        assert Rubygem.find_by_name("with_dependencies")
        assert_nil Rubygem.find_by_name("thoughtbot-shoulda")
        assert_nil Rubygem.find_by_name("rake")

        assert_equal %w[rake thoughtbot-shoulda],
          @version.dependencies.map(&:unresolved_name).sort
      end
    end

    context "that was previous an unresolved dependency" do
      setup do
        @specification = gem_specification_from_gem_fixture("with_dependencies-0.0.0")
        @rubygem       = Rubygem.new(name: @specification.name)
        @version       = @rubygem.find_or_initialize_version_from_spec(@specification)
        @version.sha256 = "dummy"

        @rubygem.update_attributes_from_gem_specification!(@version, @specification)

        @rack_dep = @version.dependencies.find_by(unresolved_name: "rake")
      end

      should "update the dependency" do
        rubygem = Rubygem.create(name: "rake")

        dependency = Dependency.find_by_id(@rack_dep.id)
        assert_nil dependency.unresolved_name
        assert_equal rubygem, dependency.rubygem
      end
    end

    context "from a Gem::Specification with pre-existing dependencies" do
      setup do
        @specification = gem_specification_from_gem_fixture("with_dependencies-0.0.0")
        Rubygem.create(name: "thoughtbot-shoulda")
        Rubygem.create(name: "rake")

        @rubygem       = Rubygem.new(name: @specification.name)
        @version       = @rubygem.find_or_initialize_version_from_spec(@specification)
        @version.sha256 = "dummy"
      end

      should "save the gem" do
        assert_nothing_raised do
          @rubygem.update_attributes_from_gem_specification!(@version, @specification)
        end

        refute_predicate @rubygem, :new_record?
        refute_predicate @version, :new_record?
        assert_equal 1, @rubygem.versions.count
        assert_equal 1, @rubygem.versions_count
        assert_equal 2, @version.dependencies.count
        assert Rubygem.exists?(name: "thoughtbot-shoulda")
        assert Rubygem.exists?(name: "rake")
      end
    end

    context "from a Gem:Specification of older version" do
      setup do
        linkset  = create(:linkset, home: "http://latest.com")
        @rubygem = create(:rubygem, name: "test", number: "1.0.0", linkset: linkset)
        gemspec  = new_gemspec("test", "0.0.1", "test", "ruby") { |spec| spec.homepage = "http://test.com" }
        version  = @rubygem.find_or_initialize_version_from_spec(gemspec)
        @rubygem.update_attributes_from_gem_specification!(version, gemspec)
      end

      should "not update linkset" do
        assert_equal "http://latest.com", @rubygem.linkset.home
      end
    end
  end

  context "#protected_days" do
    setup do
      @rubygem = create(:rubygem)
      @rubygem.update_attribute(:updated_at, 99.days.ago)
    end

    should "return number of days left till the gem namespace is protected" do
      assert_equal 1, @rubygem.protected_days
    end
  end

  context "with downloaded gems and versions created at specific times" do
    setup do
      @rubygem1 = create(:rubygem, downloads: 10)
      @rubygem2 = create(:rubygem, downloads: 20)
      @rubygem3 = create(:rubygem, downloads: 30)
      create(:version, rubygem: @rubygem1, created_at: (Gemcutter::NEWS_DAYS_LIMIT - 2.days).ago)
      create(:version, rubygem: @rubygem2, created_at: (Gemcutter::NEWS_DAYS_LIMIT - 1.day).ago)
      create(:version, rubygem: @rubygem3, created_at: (Gemcutter::POPULAR_DAYS_LIMIT + 1.day).ago)
    end

    context ".news" do
      setup do
        @news = Rubygem.news(Gemcutter::NEWS_DAYS_LIMIT)
      end

      should "not include gems updated prior to Gemcutter::NEWS_DAYS_LIMIT days ago" do
        assert_not_includes @news, @rubygem3
      end

      should "order by created_at of gem version" do
        expected_order = [@rubygem1, @rubygem2]
        assert_equal expected_order, @news
      end
    end

    context ".popular" do
      setup do
        @popular_gems = Rubygem.popular(Gemcutter::POPULAR_DAYS_LIMIT)
      end

      should "not include gems updated prior to Gemcutter::POPULAR_DAYS_LIMIT days ago" do
        assert_not_includes @popular_gems, @rubygem3
      end

      should "order by number of downloads" do
        expected_order = [@rubygem2, @rubygem1]
        assert_equal expected_order, @popular_gems
      end
    end
  end

  context "unconfirmed ownership" do
    setup do
      @rubygem               = create(:rubygem)
      @confirmed_owner       = create(:user)
      @unconfirmed_owner     = create(:user)
      @unconfirmed_ownership = create(:ownership, :unconfirmed, rubygem: @rubygem, user: @unconfirmed_owner)

      create(:ownership, rubygem: @rubygem, user: @confirmed_owner)
    end

    context "#unconfirmed_ownerships" do
      should "return only unconfirmed ownerships" do
        assert_equal [@unconfirmed_ownership], @rubygem.unconfirmed_ownerships
      end
    end

    context "#unconfirmed_ownership?" do
      should "return false when user is confirmed owner" do
        refute @rubygem.unconfirmed_ownership?(@confirmed_owner)
      end

      should "return true when user is unconfirmed owner" do
        assert @rubygem.unconfirmed_ownership?(@unconfirmed_owner)
      end
    end
  end

  context ".mfa_recommended scope" do
    should "not return gems with fewer downloads than the recommended threshold" do
      rubygem = create(:rubygem)
      GemDownload.increment(
        Rubygem::MFA_RECOMMENDED_THRESHOLD,
        rubygem_id: rubygem.id
      )

      assert_empty Rubygem.mfa_recommended
    end

    should "return gems with more downloads than the recommended threshold" do
      rubygem = create(:rubygem)
      GemDownload.increment(
        Rubygem::MFA_RECOMMENDED_THRESHOLD + 1,
        rubygem_id: rubygem.id
      )

      refute_empty Rubygem.mfa_recommended
    end
  end

  context ".mfa_required scope" do
    should "not return gems with fewer downloads than the required threshold" do
      rubygem = create(:rubygem)
      GemDownload.increment(
        Rubygem::MFA_REQUIRED_THRESHOLD,
        rubygem_id: rubygem.id
      )

      assert_empty Rubygem.mfa_required
    end

    should "return gems with more downloads than the required threshold" do
      rubygem = create(:rubygem)
      GemDownload.increment(
        Rubygem::MFA_REQUIRED_THRESHOLD + 1,
        rubygem_id: rubygem.id
      )

      assert_includes Rubygem.mfa_required, rubygem
    end
  end

  context "#mfa_requirement_satisfied_for?" do
    setup do
      @rubygem = create(:rubygem)
      @owner   = create(:user)
      create(:ownership, user: @owner, rubygem: @rubygem)
    end

    context "rubygems_mfa_required is set" do
      setup do
        metadata = { "rubygems_mfa_required" => "true" }
        create(:version, rubygem: @rubygem, number: "1.0.0", metadata: metadata)
      end

      should "not be satisfied if owner has not enabled mfa" do
        refute @rubygem.mfa_requirement_satisfied_for?(@owner)
      end

      should "be satisfied if owner has enabled mfa" do
        @owner.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        assert @rubygem.mfa_requirement_satisfied_for?(@owner)
      end
    end

    context "rubygems_mfa_required is unset for latest version" do
      setup do
        create(:version, rubygem: @rubygem, number: "1.0.0")
      end

      should "be satisfied" do
        assert @rubygem.mfa_requirement_satisfied_for?(@owner)
      end

      context "rubygems_mfa_required was set for older version" do
        setup do
          metadata = { "rubygems_mfa_required" => "true" }
          create(:version, rubygem: @rubygem, number: "0.0.9", metadata: metadata)
        end

        should "be satisfied" do
          assert @rubygem.mfa_requirement_satisfied_for?(@owner)
        end
      end
    end
  end

  context "#mfa_required_since_version" do
    setup do
      @rubygem = create(:rubygem)
      metadata = { "rubygems_mfa_required" => "true" }
      @version = create(:version, number: "1.0.0", rubygem: @rubygem, metadata: metadata)
    end

    context "rubygems_mfa_required is set on the latest version" do
      should "return latest version number" do
        assert_equal @version.number, @rubygem.mfa_required_since_version
      end
    end

    context "rubygems_mfa_required was unset and set" do
      setup do
        create(:version, number: "1.0.1", rubygem: @rubygem)
        create(:version, number: "1.0.2", rubygem: @rubygem, metadata: { "rubygems_mfa_required" => "true" })
      end

      should "return latest version number with mfa required" do
        assert_equal "1.0.2", @rubygem.mfa_required_since_version
      end
    end

    context "rubygems_mfa_required is not set on the latest version" do
      setup do
        create(:version, number: "1.0.1", rubygem: @rubygem)
      end

      should "return nil" do
        assert_nil @rubygem.mfa_required_since_version
      end
    end
  end
end
