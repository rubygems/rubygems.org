require File.dirname(__FILE__) + '/../test_helper'

class RubygemTest < ActiveSupport::TestCase
  context "with a rubygem" do
    setup do
      @rubygem = Factory(:rubygem)
    end

    should_have_many :owners, :through => :ownerships
    should_have_many :ownerships
    should_have_many :versions, :dependent => :destroy
    should_have_one :linkset, :dependent => :destroy
    should_validate_uniqueness_of :name

    context "with a user" do
      setup do
        @user = Factory(:user)
      end

      should "be owned by a user in approved ownership" do
        ownership = Factory(:ownership, :user => @user, :rubygem => @rubygem, :approved => true)
        assert @rubygem.owned_by?(@user)
      end

      should "be not owned by a user in unapproved ownership" do
        ownership = Factory(:ownership, :user => @user, :rubygem => @rubygem)
        assert !@rubygem.owned_by?(@user)
      end

      should "be not owned by a user without ownership" do
        other_user = Factory(:user)
        ownership = Factory(:ownership, :user => other_user, :rubygem => @rubygem)
        assert !@rubygem.owned_by?(@user)
      end

      should "be not owned if no ownerships" do
        assert @rubygem.ownerships.empty?
        assert !@rubygem.owned_by?(@user)
      end

      should "be not owned if no user" do
        assert !@rubygem.owned_by?(nil)
      end
    end

    should "create token" do
      assert_not_nil @rubygem.token
    end

    should "return latest version for #current_version" do
      assert_equal @rubygem.versions.first, @rubygem.current_version
    end

    should "return name with version for #to_s" do
      assert_equal "#{@rubygem.name} (#{@rubygem.current_version})", @rubygem.to_s
    end

    should "return name with downloads for #with_downloads" do
      assert_equal "#{@rubygem.name} (#{@rubygem.downloads})", @rubygem.with_downloads
    end

    should "save dependencies" do
      spec = Rubygem.pull_spec(gem_file.path)
      spec.add_dependency("liquid", ">= 1.9.0")
      spec.add_dependency("open4", "= 0.9.6")
      @rubygem.spec = spec
      @rubygem.build

      assert_equal 2, @rubygem.current_dependencies.size

      assert_equal "liquid", @rubygem.current_dependencies.first.name
      assert_equal ">= 1.9.0", @rubygem.current_dependencies.first.requirement

      assert_equal "open4", @rubygem.current_dependencies.last.name
      assert_equal "= 0.9.6", @rubygem.current_dependencies.last.requirement
    end

    should "include platform when saving version" do
      spec = Rubygem.pull_spec(gem_file.path)
      spec.platform = "mswin"
      @rubygem.spec = spec
      @rubygem.build

      version = @rubygem.current_version
      assert_not_nil version
      assert_equal "0.0.0-mswin", version.number
    end

    should "build linkset with valid homepage" do
      spec = Rubygem.pull_spec(gem_file.path)
      spec.homepage = "http://something.com"
      @rubygem.spec = spec
      @rubygem.build

      assert_not_nil @rubygem.linkset
      assert_equal spec.homepage, @rubygem.linkset.home
    end

    should "build linkset without homepage" do
      spec = Rubygem.pull_spec(gem_file.path)
      spec.homepage = nil
      @rubygem.spec = spec
      @rubygem.build

      assert_not_nil @rubygem.linkset
      assert_nil @rubygem.linkset.home
    end
  end

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
end
