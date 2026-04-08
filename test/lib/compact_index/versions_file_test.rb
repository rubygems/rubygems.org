# frozen_string_literal: true

require "test_helper"
require "compact_index"
require "helpers/compact_index_helpers"

class CompactIndex::VersionsFileTest < ActiveSupport::TestCase
  include CompactIndexHelpers

  setup do
    @file_contents = "gem1 1.1,1.2\ngem2 2.1,2.1-jruby\n"
    @file = Tempfile.new("versions.list")
    @file.write @file_contents
    @file.rewind
    @versions_file = CompactIndex::VersionsFile.new(@file.path)
  end

  teardown do
    @file&.unlink
  end

  context "#create" do
    setup do
      @create_file = Tempfile.new("create_versions.list")
      @create_versions_file = CompactIndex::VersionsFile.new(@create_file.path)
    end

    teardown do
      @create_file&.unlink
    end

    should "write one line per gem" do
      gem2_versions = [
        build_version(name: "gem2", number: "1.0.1"),
        build_version(name: "gem2", number: "1.0.2", platform: "arch")
      ]
      gems = [
        CompactIndex::Gem.new("gem5", [build_version(name: "gem5", number: "1.0.1")]),
        CompactIndex::Gem.new("gem2", gem2_versions)
      ]

      freeze_time do
        @create_versions_file.create(gems)
        expected = "created_at: #{Time.now.iso8601}\n---\n" \
                   "gem2 1.0.1,1.0.2-arch info+gem2+1.0.2\n" \
                   "gem5 1.0.1 info+gem5+1.0.1\n"

        assert_equal expected, @create_file.open.read
      end
    end

    should "add the date on top" do
      gems = [CompactIndex::Gem.new("gem1", [build_version])]

      freeze_time do
        @create_versions_file.create(gems)

        assert @create_file.open.read.start_with?("created_at: #{Time.now.iso8601}\n")
      end
    end

    should "order gems by name" do
      gems = [
        CompactIndex::Gem.new("gem_b", [build_version]),
        CompactIndex::Gem.new("gem_a", [build_version])
      ]

      freeze_time do
        @create_versions_file.create(gems)
        expected = "created_at: #{Time.now.iso8601}\n---\n" \
                   "gem_a 1.0 info+test_gem+1.0\n" \
                   "gem_b 1.0 info+test_gem+1.0\n"

        assert_equal expected, @create_file.open.read
      end
    end

    should "use the given version order" do
      versions = [
        build_version(number: "1.3.0"),
        build_version(number: "2.2"),
        build_version(number: "1.1.1"),
        build_version(number: "1.1.1"),
        build_version(number: "2.1.2")
      ]
      gems = [CompactIndex::Gem.new("test", versions)]
      @create_versions_file.create(gems)

      assert_includes @create_file.open.read, "test 1.3.0,2.2,1.1.1,1.1.1,2.1.2 info+test_gem+2.1.2"
    end

    should "use a custom timestamp when provided" do
      ts = Time.new(1999, 9, 9).iso8601
      @create_versions_file.create([], ts)

      assert @create_file.open.read.start_with?("created_at: #{ts}")
    end
  end

  context "#updated_at" do
    should "be epoch start when file does not exist" do
      assert_equal Time.at(0).utc.to_datetime, CompactIndex::VersionsFile.new("/tmp/doesntexist").updated_at
    end

    should "be epoch when created_at header does not exist" do
      assert_equal Time.at(0).utc.to_datetime, @versions_file.updated_at
    end

    should "return created_at time when the header exists" do
      file = Tempfile.new("created_at_versions")
      file.write("created_at: 2015-08-23T17:22:53-07:00\n---\ngem2 1.0.1\n")
      file.rewind
      versions_file = CompactIndex::VersionsFile.new(file.path)

      assert_equal DateTime.parse("2015-08-23T17:22:53-07:00"), versions_file.updated_at
    ensure
      file&.unlink
    end
  end

  context "#contents" do
    should "raise when there are unknown options" do
      assert_raises(ArgumentError) { @versions_file.contents(nil, foo: :bar) }
    end

    should "return the file contents" do
      assert_equal @file_contents, @versions_file.contents
    end

    should "include extra gems if given" do
      gem3_versions = [
        build_version(name: "gem3", number: "1.0.1"),
        build_version(name: "gem3", number: "1.0.2", platform: "arch")
      ]
      extra_gems = [CompactIndex::Gem.new("gem3", gem3_versions)]

      assert_equal "#{@file_contents}gem3 1.0.1,1.0.2-arch info+gem3+1.0.2\n",
                   @versions_file.contents(extra_gems)
    end

    should "have info_checksum" do
      versions = [build_version(info_checksum: "testsum", number: "1.0")]
      gems = [CompactIndex::Gem.new("test", versions)]

      assert_match(/test 1.0 testsum/, @versions_file.contents(gems))
    end

    should "have the platform" do
      versions = [build_version(name: "test", number: "1.0", platform: "jruby")]
      gems = [CompactIndex::Gem.new("test", versions)]

      assert_includes @versions_file.contents(gems), "test 1.0-jruby info+test+1.0"
    end

    should "calculate info_checksums on the fly with flag" do
      dependencies = [CompactIndex::Dependency.new("foo", "=1.0.1", "ruby", "abc123")]
      versions = [build_version(number: "1.0", platform: "ruby", dependencies: dependencies)]
      gems = [CompactIndex::Gem.new("test", versions)]

      assert_match(/test 1.0 b1c5ae823c07dba64028e4b37a2a2ba7/,
                   @versions_file.contents(gems, calculate_info_checksums: true))
    end
  end
end
