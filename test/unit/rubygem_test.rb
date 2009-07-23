require File.dirname(__FILE__) + '/../test_helper'

class RubygemTest < ActiveSupport::TestCase
  context "with a saved rubygem" do
    setup do
      @rubygem = Factory(:rubygem)
    end

    should_have_many :owners, :through => :ownerships
    should_have_many :ownerships
    should_have_many :versions, :dependent => :destroy
    should_have_one :linkset, :dependent => :destroy
    should_validate_uniqueness_of :name
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
      assert_equal "#{@rubygem.name} (#{@rubygem.versions.current})", @rubygem.to_s
    end

    should "return name for #to_s if current version doesn't exist" do
      assert_equal @rubygem.name, @rubygem.to_s
    end

    should "return name with downloads for #with_downloads" do
      assert_equal "#{@rubygem.name} (#{@rubygem.downloads})", @rubygem.with_downloads
    end

    context "building the gem" do
      setup do
        @spec = Rubygem.pull_spec(gem_file.path)
        @name = "awesome gem"
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
          @versions = "version"

          stub(@rubygem).versions { @versions }
          stub(Version).destroy_all
          stub(@versions).build
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

        context "building a new set of versions" do
          before_should "destroy versions with the given number and id" do
            stub(@rubygem).id { 42 }
            mock(Version).destroy_all(:number => @version_hash[:number], :rubygem_id => @rubygem.id)
          end

          before_should "create a new version with the given hash" do
            mock(@versions).build(@version_hash)
          end

          setup do
            stub(Version).destroy_all
            stub(@versions).build
            @rubygem.build_version(@version_hash)
          end
        end
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

    context "processing spec" do
      setup do
        @spec = Rubygem.pull_spec(gem_file.path)
        @rubygem.spec = @spec
      end

      should "save dependencies" do
        @spec.add_dependency("liquid", ">= 1.9.0")
        @spec.add_dependency("open4", "= 0.9.6")
        @rubygem.save

        assert_equal 2, @rubygem.versions.current.requirements.size
        current_dependencies = @rubygem.versions.current.dependencies
        assert_equal 2, current_dependencies.size

        liquid = current_dependencies.select { |d| d.rubygem.name == "liquid" }.first
        assert_not_nil liquid
        assert_equal ">= 1.9.0", liquid.name

        open4 = current_dependencies.select { |d| d.rubygem.name == "open4" }.first
        assert_not_nil open4
        assert_equal "= 0.9.6", open4.name
      end

      should "include platform when saving version" do
        @spec.platform = "mswin"
        @spec.date = Date.today
        @rubygem.save

        version = @rubygem.versions.current
        assert_not_nil version
        assert_equal "0.0.0-mswin", version.number
      end

      should "build linkset with valid homepage" do
        @spec.homepage = "http://something.com"
        @rubygem.build

        assert_not_nil @rubygem.linkset
        assert_equal @spec.homepage, @rubygem.linkset.home
      end

      should "build linkset without homepage" do
        @spec.homepage = nil
        @rubygem.build

        assert_not_nil @rubygem.linkset
        assert_nil @rubygem.linkset.home
      end

      should "save summary, description and rubyforge project" do
        @summary = "My gem."
        @description = "My gem is awesome."
        @rubyforge_project = "awesome"

        @spec.summary = @summary
        @spec.description = @description
        @spec.rubyforge_project = @rubyforge_project
        @rubygem.save
        @version = @rubygem.versions.latest

        assert_equal @summary, @version.summary
        assert_equal @description, @version.description
        assert_equal @rubyforge_project, @version.rubyforge_project
      end
    end

  end

  context "pulling the spec " do
    should "pull spec out of the given gem" do
      spec = Rubygem.pull_spec(gem_file.path)
      assert_not_nil spec
      assert spec.is_a?(Gem::Specification)
    end

    should "not be able to pull spec from a bad path" do
      spec = Rubygem.pull_spec("bad path")
      assert_nil spec
    end

    should "respond to spec" do
      assert Rubygem.new.respond_to?(:spec)
    end
  end

  context "saving a gem" do
    setup do
      @gem = "test-0.0.0.gem"
      @gem_file = gem_file(@gem)
      @spec = gem_spec
      stub(Gem::Format).from_file_by_path(anything).stub!.spec { @spec }
      regenerate_index

      @rubygem = Rubygem.create(:spec => @spec, :path => @gem_file.path)
    end

    context "updating a gem" do
      setup do
        @new_gem = "test-1.0.0.gem"
        @new_gem_file = gem_file(@new_gem)
        @new_spec = gem_spec(:version => "1.0.0")
        stub(Gem::Format).from_file_by_path(anything).stub!.spec { @new_spec }

        @rubygem.path = @new_gem_file.path
        @rubygem.spec = @new_spec
        @rubygem.save
      end

      should "store the gem" do
        cache_path = Gemcutter.server_path("gems", @new_gem)
        assert_not_nil @rubygem.spec
        assert_equal @new_spec.name, @rubygem.name
        assert !@rubygem.new_record?
        assert File.exists?(cache_path)
        assert_equal 0100644, File.stat(cache_path).mode
      end

      should "create a new version" do
        assert_equal 2, @rubygem.versions.size
        version = @rubygem.versions.first
        assert_not_nil version
        assert_equal @spec.authors.join(", "), version.authors
        assert_equal @spec.description, version.description
        assert_equal @spec.version.to_s, version.number
        assert_equal @spec.date, version.created_at
        assert !version.new_record?
        assert_equal 1, Linkset.find_all_by_rubygem_id(@rubygem.id).size
      end

      should "update the index" do
        source_index = Gemcutter.server_path("source_index")
        assert File.exists?(source_index)

        source_index_data = File.open(source_index) { |f| Marshal.load f.read }
        assert source_index_data.gems.has_key?(@spec.original_name)
        assert source_index_data.gems.has_key?(@new_spec.original_name)

        quick_gem = Gemcutter.server_path("quick", "Marshal.4.8", "#{@new_spec.original_name}.gemspec.rz")
        assert File.exists?(quick_gem)

        quick_gem_data = File.open(quick_gem, 'rb') { |f| Marshal.load(Gem.inflate(f.read)) }
        assert_equal @rubygem.spec, quick_gem_data

        latest_specs = Gemcutter.server_path("latest_specs.4.8")
        assert File.exists?(latest_specs)

        latest_specs_data = File.open(latest_specs) { |f| Marshal.load f.read }
        assert_equal 2, latest_specs_data.size
        assert_equal ["test", Gem::Version.new("0.0.0"), "ruby"], latest_specs_data.first
        assert_equal ["test", Gem::Version.new("1.0.0"), "ruby"], latest_specs_data.last
      end
    end

    should "store the gem" do
      cache_path = Gemcutter.server_path("gems", @gem)
      assert_not_nil @rubygem.spec
      assert_equal @spec.name, @rubygem.name
      assert !@rubygem.new_record?
      assert File.exists?(cache_path)
      assert_equal 0100644, File.stat(cache_path).mode
    end

    should "create a new version" do
      version = @rubygem.versions.first
      assert_not_nil version
      assert_equal @spec.authors.join(", "), version.authors
      assert_equal @spec.description, version.description
      assert_equal @spec.version.to_s, version.number
      assert_equal @spec.date, version.created_at
      assert !version.new_record?
    end

    should "update the index" do
      source_index = Gemcutter.server_path("source_index")
      assert File.exists?(source_index)

      source_index_data = File.open(source_index) { |f| Marshal.load f.read }
      assert source_index_data.gems.has_key?(@spec.original_name)

      quick_gem = Gemcutter.server_path("quick", "Marshal.4.8", "#{@spec.original_name}.gemspec.rz")
      assert File.exists?(quick_gem)

      quick_gem_data = File.open(quick_gem, 'rb') { |f| Marshal.load(Gem.inflate(f.read)) }
      assert_equal @rubygem.spec, quick_gem_data

      latest_specs = Gemcutter.server_path("latest_specs.4.8")
      assert File.exists?(latest_specs)

      latest_specs_data = File.open(latest_specs) { |f| Marshal.load f.read }
      assert_equal 1, latest_specs_data.size
      assert_equal ["test", Gem::Version.new("0.0.0"), "ruby"], latest_specs_data.first
    end
  end

  context "with some rubygems" do
    setup do
      @rubygem_without_version = Factory(:rubygem, :spec => nil)
      @rubygem_with_version = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem_with_version)
    end
    should "return only gems with versions for #with_versions" do
      assert Rubygem.with_versions.include?(@rubygem_with_version)
      assert !Rubygem.with_versions.include?(@rubygem_without_version)
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
