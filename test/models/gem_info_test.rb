# frozen_string_literal: true

require "test_helper"

class GemInfoTest < ActiveSupport::TestCase
  setup do
    Rails.cache.delete("names")
    Rails.cache.delete("info_v2/example")
  end

  teardown do
    Rails.cache.delete("names")
    Rails.cache.delete("info_v2/example")
  end

  context "#compact_index_info" do
    setup do
      rubygem = create(:rubygem, name: "example")
      @version = create(:version, rubygem: rubygem, number: "1.0.0", info_checksum_v2: "qw2dwe")
      dep = create(:rubygem, name: "exmaple_dep")
      create(:dependency, rubygem: dep, version: @version)

      @expected_info = [CompactIndex::GemVersionV2.new(
        "1.0.0",
        "ruby",
        "b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78",
        "qw2dwe",
        [CompactIndex::Dependency.new("exmaple_dep", "= 1.0.0")],
        ">= 2.0.0",
        ">= 2.6.3",
        @version.created_at.utc.iso8601
      )]

      @expected_info_checksum = Digest::MD5.hexdigest(CompactIndex.info(@expected_info))
    end

    should "return v2 gem version and dependency with created_at" do
      info = GemInfo.new("example").compact_index_info

      assert_equal @expected_info, info
    end

    should "compute v2 info checksum with created_at" do
      assert_equal @expected_info_checksum, GemInfo.new("example").info_checksum
    end

    should "write v2 cache" do
      Rails.cache.expects(:write).with("info_v2/example", @expected_info)

      GemInfo.new("example").compact_index_info
    end

    should "read v2 from cache when cache exists" do
      Rails.cache.expects(:read).with("info_v2/example")

      info = GemInfo.new("example").compact_index_info

      assert_equal @expected_info, info
    end

    should "recompute when v2 cache deserialization fails" do
      Rails.cache.expects(:read).with("info_v2/example").raises(TypeError, "struct size differs")

      info = nil
      assert_nothing_raised { info = GemInfo.new("example").compact_index_info }

      assert_equal @expected_info, info
    end
  end

  context ".ordered_names" do
    setup do
      %w[abc bcd abd].each { |name| create(:rubygem, name:, indexed: true) }

      create(:rubygem, name: "abe", indexed: false)

      @ordered_names = %w[abc abd bcd]
    end

    should "order rubygems by name" do
      names = GemInfo.ordered_names

      assert_equal @ordered_names, names
    end

    should "write cache" do
      Rails.cache.expects(:write).with("names", @ordered_names)

      GemInfo.ordered_names
    end

    should "read from cache when cache exists" do
      Rails.cache.expects(:read).with("names")

      names = GemInfo.ordered_names

      assert_equal %w[abc abd bcd], names
    end
  end

  context ".compact_index_versions" do
    setup do
      create(:version, number: "0.0.1", created_at: 10.days.ago)
      rubygem = create(:rubygem, name: "foo")
      create(:version, rubygem: rubygem, number: "2.0.0", created_at: 2.days.ago, info_checksum_v2: "v2qw2dwe")
      create(:version, rubygem: rubygem, number: "1.0.1", created_at: 3.days.ago, info_checksum_v2: "v232ddwe")

      @expected_versions =
        [CompactIndex::Gem.new("foo", [CompactIndex::GemVersion.new("1.0.1", "ruby", nil, "v232ddwe")]),
         CompactIndex::Gem.new("foo", [CompactIndex::GemVersion.new("2.0.0", "ruby", nil, "v2qw2dwe")])]
    end

    should "return all versions created after given date using v2 checksum" do
      versions = GemInfo.compact_index_versions(4.days.ago)

      assert_equal @expected_versions, versions
    end

    should "return yanked versions using v2 yanked checksum" do
      rubygem = create(:rubygem, name: "bar")
      create(:version, :yanked, rubygem: rubygem, number: "1.0.0", created_at: 10.days.ago,
                                yanked_at: 1.day.ago, yanked_info_checksum_v2: "v2yanked")

      versions = GemInfo.compact_index_versions(4.days.ago)

      assert_includes versions,
        CompactIndex::Gem.new("bar", [CompactIndex::GemVersion.new("-1.0.0", "ruby", nil, "v2yanked")])
    end
  end

  context ".compact_index_public_versions" do
    setup do
      @ts               = 5.minutes.ago
      @version          = create(:version, number: "0.0.1", created_at: @ts, info_checksum_v2: "v2qw2dwe")

      _updated_after_ts = create(:version, number: "2.0.0", created_at: @ts + 1.second, info_checksum_v2: "v2qw2dwe")
    end

    should "not return version updated after ts" do
      versions = GemInfo.compact_index_public_versions(@ts)

      expected_versions = [CompactIndex::Gem.new(
        @version.rubygem.name,
        [CompactIndex::GemVersion.new(@version.number, @version.platform, @version.sha256, @version.info_checksum_v2)]
      )]

      assert_equal expected_versions, versions
    end

    should "not return yanked versions" do
      rubygem = create(:rubygem, name: "bar")
      indexed_version = create(:version, rubygem: rubygem, number: "1.0.0", created_at: 10.minutes.ago, info_checksum_v2: "v2qw2dwe")
      create(:version, :yanked, rubygem: rubygem, number: "2.0.0", created_at: 9.minutes.ago,
                                yanked_at: 8.minutes.ago, yanked_info_checksum_v2: "v2yanked")

      versions = GemInfo.compact_index_public_versions(@ts)

      assert_includes versions, CompactIndex::Gem.new("bar", [CompactIndex::GemVersion.new("1.0.0", "ruby", indexed_version.sha256, "v2yanked")])
    end

    should "fall back to info_checksum_v2 for yanked rows missing yanked_info_checksum_v2" do
      rubygem = create(:rubygem, name: "bar")
      indexed_version = create(:version, rubygem: rubygem, number: "1.0.0", created_at: 10.minutes.ago, info_checksum_v2: "v2qw2dwe")
      create(:version, :yanked, rubygem: rubygem, number: "2.0.0", created_at: 9.minutes.ago,
                                yanked_at: 8.minutes.ago, info_checksum_v2: "v2qw2dwe",
                                yanked_info_checksum_v2: nil)

      versions = GemInfo.compact_index_public_versions(@ts)

      assert_includes versions, CompactIndex::Gem.new("bar", [CompactIndex::GemVersion.new("1.0.0", "ruby", indexed_version.sha256, "v2qw2dwe")])
    end
  end
end
