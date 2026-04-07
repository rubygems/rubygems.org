# frozen_string_literal: true

require "test_helper"
require "compact_index"

# Named CompactIndexLibTest to avoid superclass mismatch with
# CompactIndexTest < ActionDispatch::IntegrationTest in test/integration/api/compact_index_test.rb
class CompactIndexLibTest < ActiveSupport::TestCase
  context ".names" do
    should "return the gem list for one gem name" do
      assert_equal "---\ngem\n", CompactIndex.names(["gem"])
    end

    should "return the gem list for multiple gem names" do
      assert_equal "---\ngem-1\ngem_2\n", CompactIndex.names(%w[gem-1 gem_2])
    end
  end

  context ".versions" do
    should "delegate to VersionsFile#contents" do
      file = Tempfile.new("versions-endpoint")
      versions_file = CompactIndex::VersionsFile.new(file.path)
      gems = [CompactIndex::Gem.new("test", [build_version])]

      assert_equal versions_file.contents(gems), CompactIndex.versions(versions_file, gems)
    ensure
      file&.unlink
    end
  end

  context ".info" do
    should "format version without dependencies" do
      param = [build_version(number: "1.0.1")]

      assert_equal "---\n1.0.1 |checksum:sum+test_gem+1.0.1\n", CompactIndex.info(param)
    end

    should "format multiple versions" do
      param = [
        build_version(number: "1.0.1", checksum: "abc1"),
        build_version(number: "1.0.2", checksum: "abc2")
      ]

      assert_equal "---\n1.0.1 |checksum:abc1\n1.0.2 |checksum:abc2\n", CompactIndex.info(param)
    end

    should "format one dependency" do
      deps = [CompactIndex::Dependency.new("foo", "=1.0.1", "ruby", "abc123")]
      param = [build_version(number: "1.0.1", dependencies: deps)]

      assert_equal "---\n1.0.1 foo:=1.0.1|checksum:sum+test_gem+1.0.1\n", CompactIndex.info(param)
    end

    should "format multiple dependencies" do
      deps = [
        CompactIndex::Dependency.new("foo1", "=1.0.1", "ruby", "abc123"),
        CompactIndex::Dependency.new("foo2", "<2.0", "ruby", "abc123")
      ]
      param = [build_version(number: "1.0.1", dependencies: deps)]

      assert_equal "---\n1.0.1 foo1:=1.0.1,foo2:<2.0|checksum:sum+test_gem+1.0.1\n", CompactIndex.info(param)
    end

    should "format dependency with multiple version constraints" do
      deps = [CompactIndex::Dependency.new("foo", "<2.0, >1.0", "ruby", "abc123")]
      param = [build_version(number: "1.0.1", dependencies: deps)]

      assert_equal "---\n1.0.1 foo:<2.0&>1.0|checksum:sum+test_gem+1.0.1\n", CompactIndex.info(param)
    end

    should "sort the requirements" do
      deps = [CompactIndex::Dependency.new("foo", ">1.0, <2.0", "ruby", "abc123")]
      param = [build_version(number: "1.0.1", dependencies: deps)]

      assert_equal "---\n1.0.1 foo:<2.0&>1.0|checksum:sum+test_gem+1.0.1\n", CompactIndex.info(param)
    end

    should "include dependency platform" do
      deps = [
        CompactIndex::Dependency.new("a", "=1.1", "jruby", "abc123"),
        CompactIndex::Dependency.new("b", "= 1.2", "darwin-13", "abc123")
      ]
      param = [build_version(number: "1.0.1", dependencies: deps)]

      assert_equal "---\n1.0.1 a:=1.1-jruby,b:= 1.2-darwin-13|checksum:sum+test_gem+1.0.1\n", CompactIndex.info(param)
    end

    should "show ruby required version" do
      param = [build_version(number: "1.0.1", ruby_version: ">1.8")]

      assert_equal "---\n1.0.1 |checksum:sum+test_gem+1.0.1,ruby:>1.8\n", CompactIndex.info(param)
    end

    should "show ruby required version with multiple requirements" do
      param = [build_version(number: "1.0.1", ruby_version: "< 2.5, >=2.2")]

      assert_equal "---\n1.0.1 |checksum:sum+test_gem+1.0.1,ruby:< 2.5&>=2.2\n", CompactIndex.info(param)
    end

    should "show rubygems required version" do
      param = [build_version(number: "1.0.1", rubygems_version: "=2.0")]

      assert_equal "---\n1.0.1 |checksum:sum+test_gem+1.0.1,rubygems:=2.0\n", CompactIndex.info(param)
    end

    should "show rubygems required version with multiple requirements" do
      param = [build_version(number: "1.0.1", rubygems_version: ">2.0, <3.1")]

      assert_equal "---\n1.0.1 |checksum:sum+test_gem+1.0.1,rubygems:<3.1&>2.0\n", CompactIndex.info(param)
    end

    should "show both rubygems and ruby required versions" do
      param = [build_version(number: "1.0.1", ruby_version: ">1.9", rubygems_version: ">2.0")]

      assert_equal "---\n1.0.1 |checksum:sum+test_gem+1.0.1,ruby:>1.9,rubygems:>2.0\n", CompactIndex.info(param)
    end

    should "add platform next to version number" do
      param = [build_version(number: "1.0.1", platform: "jruby")]

      assert_equal "---\n1.0.1-jruby |checksum:sum+test_gem+1.0.1\n", CompactIndex.info(param)
    end
  end

  context "GemVersion#<=>" do
    should "sort by number" do
      v1 = build_version(number: "1.0")
      v2 = build_version(number: "2.0")

      assert_equal(-1, v1 <=> v2)
      assert_equal 1, v2 <=> v1
    end

    should "sort by platform when numbers are equal" do
      v1 = build_version(number: "1.0", platform: "java")
      v2 = build_version(number: "1.0", platform: "ruby")

      assert_equal(-1, v1 <=> v2)
    end

    should "return zero for equal versions" do
      v1 = build_version(number: "1.0", platform: "ruby")
      v2 = build_version(number: "1.0", platform: "ruby")

      assert_equal 0, v1 <=> v2
    end
  end

  context "Dependency#version_and_platform" do
    should "include platform for non-ruby platform" do
      dep = CompactIndex::Dependency.new("foo", "=1.0", "jruby", "abc")

      assert_equal "=1.0-jruby", dep.version_and_platform
    end

    should "exclude platform for ruby platform" do
      dep = CompactIndex::Dependency.new("foo", "=1.0", "ruby", "abc")

      assert_equal "=1.0", dep.version_and_platform
    end
  end

  private

  def build_version(**args)
    name = args.fetch(:name, "test_gem")
    number = args.fetch(:number, "1.0")
    CompactIndex::GemVersion.new(
      number,
      args[:platform],
      args.fetch(:checksum, "sum+#{name}+#{number}"),
      args.fetch(:info_checksum, "info+#{name}+#{number}"),
      args[:dependencies],
      args[:ruby_version],
      args[:rubygems_version]
    )
  end
end
