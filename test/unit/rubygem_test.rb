require File.dirname(__FILE__) + '/../test_helper'

class RubygemTest < ActiveSupport::TestCase
  context "with a saved rubygem" do
    setup do
      @rubygem = Factory(:rubygem, :name => "SomeGem")
    end
    subject { @rubygem }

    should_have_many :owners, :through => :ownerships
    should_have_many :ownerships
    should_have_many :versions, :dependent => :destroy
    should_have_one :linkset, :dependent => :destroy
    should_validate_uniqueness_of :name

    should "find by slug or name" do
      assert_equal @rubygem, Rubygem.super_find("SomeGem")
      assert_equal @rubygem, Rubygem.super_find("somegem")
    end
  end

  context "with a rubygem" do
    setup do
      @rubygem = Factory.build(:rubygem)
    end

    context "numbers in rubygem name" do
      should "not be valid if name consists solely of numbers" do
        @rubygem.name = "123456"
        assert !@rubygem.valid?
        assert_equal "must include at least one letter.", @rubygem.errors.on(:name)
      end
      should "be valid if name has numbers in it" do
        @rubygem.name = "123test123"
        assert @rubygem.valid?
      end
      should "be valid if name has no numbers in it" do
        @rubygem.name = "test"
        assert @rubygem.valid?
      end
    end

    context "with a user" do
      setup do
        @rubygem.save
        @user = Factory(:user)
      end

      should "always allow push when rubygem is new" do
        stub(@rubygem).new_record? { true }
        assert @rubygem.allow_push_from?(@user)
      end

      should "be owned by a user in approved ownership" do
        ownership = Factory(:ownership, :user => @user, :rubygem => @rubygem, :approved => true)
        assert @rubygem.owned_by?(@user)
        assert !@rubygem.unowned?
        assert @rubygem.allow_push_from?(@user)
      end

      should "be not owned by a user in unapproved ownership" do
        ownership = Factory(:ownership, :user => @user, :rubygem => @rubygem)
        assert !@rubygem.owned_by?(@user)
        assert @rubygem.unowned?
        assert !@rubygem.allow_push_from?(@user)
      end

      should "be not owned by a user without ownership" do
        other_user = Factory(:user)
        ownership = Factory(:ownership, :user => other_user, :rubygem => @rubygem)
        assert !@rubygem.owned_by?(@user)
        assert @rubygem.unowned?
        assert !@rubygem.allow_push_from?(@user)
      end

      should "be not owned if no ownerships" do
        assert @rubygem.ownerships.empty?
        assert !@rubygem.owned_by?(@user)
        assert @rubygem.unowned?
        assert !@rubygem.allow_push_from?(@user)
      end

      should "be not owned if no user" do
        assert !@rubygem.owned_by?(nil)
        assert @rubygem.unowned?
        assert !@rubygem.allow_push_from?(@user)
      end
    end

    should "return current version" do
      assert_equal @rubygem.versions.first, @rubygem.versions.current
    end

    should "return name with version for #to_s" do
      @rubygem.save
      @rubygem.versions.create(:number => "0.0.0")
      assert_equal "#{@rubygem.name} (#{@rubygem.versions.current})", @rubygem.to_s
    end

    should "return name for #to_s if current version doesn't exist" do
      assert_equal @rubygem.name, @rubygem.to_s
    end

    should "return name with downloads for #with_downloads" do
      assert_equal "#{@rubygem.name} (#{@rubygem.downloads})", @rubygem.with_downloads
    end

    should "return a bunch of json" do
      Factory(:version, :rubygem => @rubygem)
      hash = JSON.parse(@rubygem.to_json)
      assert_equal @rubygem.name, hash["name"]
      assert_equal @rubygem.slug, hash["slug"]
      assert_equal @rubygem.downloads, hash["downloads"]
      assert_equal @rubygem.versions.current.number, hash["version"]
      assert_equal @rubygem.versions.current.authors, hash["authors"]
      assert_equal @rubygem.versions.current.info, hash["info"]
      assert_equal @rubygem.versions.current.rubyforge_project, hash["rubyforge_project"]
    end

    context "saving the homepage" do
      setup do
        @homepage = "http://gemcutter.org"
      end

      should "build linkset if it doesn't exist" do
        stub(@rubygem).linkset { nil }
        mock(@rubygem).build_linkset(:home => @homepage)
        @rubygem.build_links(@homepage)
      end

      should "not build linkset if it exists but still set the home page" do
        linkset = "linkset"
        stub(@rubygem).linkset { linkset }
        mock(linkset).home = @homepage
        @rubygem.build_links(@homepage)
      end
    end

    context "with some versions" do
      setup do
        @version_hash = {:number => "0.0.0"}
        @versions = "versions"

        stub(@rubygem).versions { @versions }
      end

      context "building a version" do
        should "build new version if none exists" do
          mock(@versions).find_by_number(@version_hash[:number]) { nil }
          mock(@versions).build(@version_hash)
          @rubygem.build_version(@version_hash)
        end

        should "set attributes of existing version if one exists" do
          existing_version = "existing version"
          mock(existing_version).attributes = @version_hash
          mock(@versions).find_by_number(@version_hash[:number]) { existing_version }
          mock(@versions).build.never
          @rubygem.build_version(@version_hash)

          mock(existing_version).save
          @rubygem.save
        end
      end

      context "building a new set of dependencies" do
        setup do
          @version = "version"
          @dependencies = [@dep]
          stub(@version).dependencies { @dependencies }
          stub(@versions).last { @version }
          stub(@dep).name { "dependency" }
          stub(@dep).requirements_list { Gem::Requirement.new("= 1.0.0") }
        end

        should "build a dependency" do
          mock(@dependencies).build(:rubygem_name => @dep.name, :name => @dep.requirements_list.to_s)
          @rubygem.build_dependencies(@dependencies)
        end
      end
    end

    context "building the gem" do
      setup do
        @name = "awesome gem"
      end

      context "setting the name" do
        before_should "set name only if name is blank" do
          stub(@rubygem).name { "" }
          mock(@rubygem).name = @name
        end

        should "not set name if name has changed" do
          stub(@rubygem).name { @name }
          dont_allow(@rubygem).name = @name
        end

        setup do
          @rubygem.build_name(@name)
        end
      end
    end

    context "with a user" do
      setup do
        @user = Factory(:user)
      end

      context "building ownership" do
        before_should "set user as owner if new record" do
          stub(@rubygem).new_record? { true }
          mock(@rubygem).ownerships.mock!.build(:user => @user, :approved => true)
        end

        before_should "not set user as owner if new record" do
          stub(@rubygem).new_record? { false }
          stub(@rubygem).ownerships.mock!.build.never
        end

        setup do
          @rubygem.build_ownership(@user)
        end
      end
    end
  end

  context "with some rubygems" do
    setup do
      @rubygem_without_version = Factory(:rubygem)
      @rubygem_with_version = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem_with_version)
    end

    should "return only gems with versions for #with_versions" do
      assert Rubygem.with_versions.include?(@rubygem_with_version)
      assert !Rubygem.with_versions.include?(@rubygem_without_version)
    end

    should "be hosted or not" do
      assert ! @rubygem_without_version.hosted?
      assert @rubygem_with_version.hosted?
    end

    should "return a blank rubyforge project without any versions" do
      assert_equal "", @rubygem_without_version.rubyforge_project
    end

    should "return the current rubyforge project with a version" do
      assert_equal @rubygem_with_version.versions.current.rubyforge_project,
                   @rubygem_with_version.rubyforge_project
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

      @gems = [@thin, @rake, @json, @thor, @rack, @dust]
      @gems.each { |g| Factory(:version, :rubygem => g) }
    end

    should "give a count of only rubygems with versions" do
      assert_equal 6, Rubygem.total_count
    end

    should "only return the latest gems with versions" do
      assert_equal [@rack, @thor, @dust, @json, @rake], Rubygem.latest
    end

    should "only latest downloaded versions" do
      assert_equal [@thin, @rake, @json, @thor, @rack], Rubygem.downloaded
    end
  end

  context "when some gems exist with titles and versions that have descriptions" do
    setup do
      @apple_pie = Factory(:rubygem, :name => 'apple')
      Factory(:version, :description => 'pie', :rubygem => @apple_pie)

      @orange_julius = Factory(:rubygem, :name => 'orange')
      Factory(:version, :description => 'julius', :rubygem => @orange_julius)
    end

    should "find rubygems by name on #search" do
      assert Rubygem.search('apple').include?(@apple_pie)
      assert Rubygem.search('orange').include?(@orange_julius)

      assert ! Rubygem.search('apple').include?(@orange_julius)
      assert ! Rubygem.search('orange').include?(@apple_pie)
    end

    should "find rubygems by description on #search" do
      assert Rubygem.search('pie').include?(@apple_pie)
      assert Rubygem.search('julius').include?(@orange_julius)

      assert ! Rubygem.search('pie').include?(@orange_julius)
      assert ! Rubygem.search('julius').include?(@apple_pie)
    end
  end
end
