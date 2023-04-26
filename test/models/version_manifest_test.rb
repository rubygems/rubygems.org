require "test_helper"

class VersionsManifestTest < ActiveSupport::TestCase
  def create_entry(path, sha256, body: rand.to_s, mime: "text/plain")
    RubygemContents::Entry.new(path: path, sha256: sha256, body: body, mime: mime, size: body.size)
  end

  setup do
    RubygemFs.mock!
    @manifest = VersionManifest.new(number: "0.1.0", gem: "gemname")
    @manifest2 = VersionManifest.new(number: "0.2.0", gem: "gemname")
    @manifest3 = VersionManifest.new(number: "0.2.0", platform: "platform", gem: "gemname")

    @files = [
      create_entry("path1", "hex1-A"),
      create_entry("path2", "hex2-A"),
      create_entry("path3", "hex3-A"),
      create_entry("path4", "hex3-A")
    ]
    @spec = stub(to_ruby: "#{@manifest.gem}-#{@manifest.version}.gemspec")
  end

  teardown do
    RubygemFs.mock!
  end

  context "#checksums_root" do
    should "return a path" do
      assert_equal "gems/gemname/checksums/", @manifest.checksums_root
    end
  end

  context "#checksums_key" do
    should "return a path" do
      assert_equal "gems/gemname/checksums/0.1.0.sha256", @manifest.checksums_key
      assert_equal "gems/gemname/checksums/0.2.0.sha256", @manifest2.checksums_key
    end

    should "return a path with a platform" do
      assert_equal "gems/gemname/checksums/0.2.0-platform.sha256", @manifest3.checksums_key
    end
  end

  context "#path_root" do
    should "return a path" do
      assert_equal "gems/gemname/paths/0.1.0/", @manifest.path_root
      assert_equal "gems/gemname/paths/0.2.0/", @manifest2.path_root
    end

    should "return a path with a platform" do
      assert_equal "gems/gemname/paths/0.2.0-platform/", @manifest3.path_root
    end
  end

  context "#path_key" do
    should "return a path" do
      assert_equal "gems/gemname/paths/0.1.0/path1", @manifest.path_key("path1")
      assert_equal "gems/gemname/paths/0.2.0/lib/to/path.rb", @manifest2.path_key("lib/to/path.rb")
    end

    should "return a path with a platform" do
      assert_equal "gems/gemname/paths/0.2.0-platform/lib/to/path.rb", @manifest3.path_key("lib/to/path.rb")
    end
  end

  context "#spec_key" do
    should "return a path" do
      assert_equal "gems/gemname/specs/gemname-0.1.0.gemspec", @manifest.spec_key
      assert_equal "gems/gemname/specs/gemname-0.2.0.gemspec", @manifest2.spec_key
    end

    should "return a path with a platform" do
      assert_equal "gems/gemname/specs/gemname-0.2.0-platform.gemspec", @manifest3.spec_key
    end
  end

  context "#spec" do
    should "return nil for missing version" do
      assert_nil @manifest.spec
    end

    should "return the spec" do
      @manifest.store_spec @spec

      assert_equal @spec.to_ruby, @manifest.spec
    end
  end

  context "#entry" do
    should "return nil for a nil path" do
      assert_nil @manifest.entry(nil)
    end

    should "return nil for a non-indexed file" do
      assert_nil @manifest.entry("nope.rb")
    end

    should "return nil for a file not on this version" do
      @manifest2.store_entry(create_entry("path", "hex"))

      assert_nil @manifest.entry("path")
    end

    should "return an entry for an indexed file" do
      @manifest.store_entries(@files)

      assert_equal "hex1-A", @manifest.entry("path1").fingerprint
      assert_equal "hex2-A", @manifest.entry("path2").fingerprint
      assert_equal "hex3-A", @manifest.entry("path3").fingerprint
      assert_equal "hex3-A", @manifest.entry("path4").fingerprint
    end
  end

  context "#paths" do
    should "return empty Array for missing version" do
      assert_empty VersionManifest.new(gem: "nope", number: "0.1.0").paths
    end

    should "have the same files indexed as entered" do
      @manifest.store_entries(@files)

      assert_equal %w[path1 path2 path3 path4], @manifest.paths, "manifest files should match"
    end
  end

  context "#checksums" do
    should "return empty checksums for missing version" do
      assert_empty VersionManifest.new(gem: "nope", number: "0.1.0").checksums.values
    end

    should "return checksums for version" do
      @manifest.store_entries(@files)

      assert_equal %w[hex1-A hex2-A hex3-A], @manifest.checksums.values.uniq.sort, "manifest checksums should match"
    end
  end

  context "#checksums_file" do
    should "return empty checksums for missing version" do
      assert_nil VersionManifest.new(gem: "nope", number: "0.1.0").checksums_file
    end

    should "return checksums for version" do
      @manifest.store_entries(@files)

      assert_equal <<~CHECKSUMS, @manifest.checksums_file
        hex1-A  path1
        hex2-A  path2
        hex3-A  path3
        hex3-A  path4
      CHECKSUMS
    end
  end

  context "#store_package" do
    should "raise if the package is nil" do
      manifest = VersionManifest.new(gem: "test", number: "0.1.0")

      assert_raises(ArgumentError) do
        manifest.store_package(nil)
      end
    end

    should "store the package" do
      gem = gem_file
      package = Gem::Package.new(gem)
      @manifest.store_package(package)

      assert_equal package.spec.to_ruby, @manifest.spec
      assert_equal package.contents.sort, @manifest.paths.sort
    ensure
      gem&.close
    end
  end

  context "#store_entries" do
    should "handle empty entries" do
      @manifest.store_entries []

      assert_empty @manifest.paths
    end

    should "store the entries" do
      @manifest.store_entries(@files)

      assert_equal @files.map(&:path).sort, @manifest.paths.sort
      assert_equal @files.to_h { |e| [e.path, e.sha256] }, @manifest.checksums
    end
  end

  context "#store_spec" do
    should "store the spec" do
      @manifest.store_spec(@spec)

      assert_equal @spec.to_ruby, @manifest.spec
    end
  end

  context "#yank" do
    setup do
      @manifest.store_entries(@files)
      @manifest.store_spec(@spec)

      @files2 = [
        create_entry("path1", "hex1-B"), # path1 changes every version
        create_entry("path2", "hex2-B"), # path2 changes here, not on the 3rd
        create_entry("path3", "hex3-A"), # path3 never changes
        create_entry("path4", "hex3-A")  # path4 is the same file as path3, until manifest3
      ]
      @manifest2.store_entries(@files2)
      @spec2 = stub(to_ruby: "#{@manifest2.gem}-#{@manifest2.version}.gemspec")
      @manifest2.store_spec(@spec2)

      @files3 = [
        create_entry("path1", "hex1-C"), # path1 changes every version
        create_entry("path2", "hex2-B"), # path2 remains unchanged from v2
        create_entry("path3", "hex3-A"), # path3 never changes
        create_entry("path4", "hex4-A"), # path4 changes to a unique file in v3
        create_entry("path5", "hex5-A")  # path5 is a new file on the third version
      ]
      @manifest3.store_entries(@files3)
      @spec3 = stub(to_ruby: "#{@manifest3.gem}-#{@manifest3.version}.gemspec")
      @manifest3.store_spec(@spec3)
    end

    should "delete all path files for a version" do
      @manifest2.yank

      assert_empty @manifest2.paths
      @files2.each do |entry|
        assert_nil @manifest2.entry(entry.path), "path #{entry.path} should be deleted"
      end
    end

    should "delete all content files unique to the yanked version" do
      @manifest2.yank

      assert_equal %w[hex1-A hex2-A hex3-A], @manifest.checksums.values.uniq.sort
      assert_equal %w[hex1-C hex2-B hex3-A hex4-A hex5-A], @manifest3.checksums.values.uniq.sort
      assert_equal %w[hex1-A hex1-C hex2-A hex2-B hex3-A hex4-A hex5-A], @manifest.contents.keys
    end

    should "fall back to a full contents scan if the checksums file is missing (partial upload)" do
      @manifest2.fs.remove(@manifest2.checksums_key)

      @manifest2.yank

      assert_equal %w[hex1-A hex2-A hex3-A], @manifest.checksums.values.uniq.sort
      assert_equal %w[hex1-C hex2-B hex3-A hex4-A hex5-A], @manifest3.checksums.values.uniq.sort
      assert_equal %w[hex1-A hex1-C hex2-A hex2-B hex3-A hex4-A hex5-A], @manifest.contents.keys
    end

    should "delete all paths for the yanked version" do
      @manifest3.yank

      refute_empty @manifest.paths
      refute_empty @manifest2.paths
      assert_empty @manifest3.paths
    end

    should "delete the spec for the yanked version" do
      @manifest.yank

      refute @manifest.spec
      assert @manifest2.spec
      assert @manifest3.spec
    end

    should "delete all files when all versions are yanked" do
      @manifest.yank
      @manifest2.yank
      @manifest3.yank

      assert_empty @manifest.checksums
      assert_empty @manifest2.checksums
      assert_empty @manifest3.checksums

      assert_empty @manifest.contents.keys

      assert_empty @manifest.paths
      assert_empty @manifest2.paths
      assert_empty @manifest3.paths

      assert_nil @manifest.spec
      assert_nil @manifest2.spec
      assert_nil @manifest3.spec
    end

    should "gracefully no-op when there's nothing to delete" do
      @manifest.yank

      @manifest.yank
    end
  end

  context "#==" do
    should "return true for the same gem and number" do
      assert_equal @manifest, VersionManifest.new(gem: "gemname", number: "0.1.0")
    end

    should "return true for the same gem and number and platform" do
      assert_equal @manifest3, VersionManifest.new(gem: "gemname", number: "0.2.0", platform: "platform")
    end

    should "return false for the same gem and number with different platform" do
      refute_equal @manifest, VersionManifest.new(gem: "gemname", number: "0.1.0", platform: "platform")
      refute_equal @manifest3, VersionManifest.new(gem: "gemname", number: "0.2.0", platform: "other")
      refute_equal @manifest, @manifest2
      refute_equal @manifest, @manifest3
    end

    should "return false for the different gem and matching version" do
      refute_equal @manifest, VersionManifest.new(gem: "other", number: "0.1.0")
      refute_equal @manifest3, VersionManifest.new(gem: "other", number: "0.2.0", platform: "platform")
    end
  end
end
