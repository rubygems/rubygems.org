# frozen_string_literal: true

require "test_helper"

class CompactIndexVersionsTest < ActiveSupport::TestCase
  setup do
    @ts = 5.minutes.ago
  end

  context ".compact_index_versions" do
    should "return all versions created after given date" do
      create(:version, number: "0.0.1", created_at: 10.days.ago)
      rubygem = create(:rubygem, name: "foo")
      create(:version, rubygem: rubygem, number: "2.0.0", created_at: 2.days.ago, info_checksum_v2: "v2qw2dwe")
      create(:version, rubygem: rubygem, number: "1.0.1", created_at: 3.days.ago, info_checksum_v2: "v232ddwe")

      versions = GemInfo.compact_index_versions(4.days.ago)

      expected_versions = [
        CompactIndex::Gem.new("foo", [CompactIndex::GemVersion.new("1.0.1", "ruby", nil, "v232ddwe")]),
        CompactIndex::Gem.new("foo", [CompactIndex::GemVersion.new("2.0.0", "ruby", nil, "v2qw2dwe")])
      ]

      assert_equal expected_versions, versions
    end

    should "return yanked versions" do
      rubygem = create(:rubygem, name: "bar")
      create(:version, :yanked, rubygem: rubygem, number: "1.0.0", created_at: 10.days.ago,
                                yanked_at: 1.day.ago, yanked_info_checksum_v2: "v2yanked")

      versions = GemInfo.compact_index_versions(4.days.ago)

      assert_includes versions,
        CompactIndex::Gem.new("bar", [CompactIndex::GemVersion.new("-1.0.0", "ruby", nil, "v2yanked")])
    end
  end

  context ".compact_index_public_versions" do
    should "not return version updated after timestamp" do
      version = create(:version, number: "0.0.1", created_at: @ts, info_checksum_v2: "v2qw2dwe")
      _updated_after_ts = create(:version, number: "2.0.0", created_at: @ts + 1.second, info_checksum_v2: "v2qw2dwe")

      versions = GemInfo.compact_index_public_versions(@ts)

      expected_versions = [CompactIndex::Gem.new(
        version.rubygem.name,
        [CompactIndex::GemVersion.new(version.number, version.platform, version.sha256, version.info_checksum_v2)]
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

    should "stream public versions one gem at a time" do
      rubygem = create(:rubygem, name: "bar")
      indexed_version = create(:version, rubygem: rubygem, number: "1.0.0", created_at: 10.minutes.ago, info_checksum_v2: "v2qw2dwe")
      create(:version, :yanked, rubygem: rubygem, number: "2.0.0", created_at: 9.minutes.ago,
                                yanked_at: 8.minutes.ago, yanked_info_checksum_v2: "v2yanked")

      versions = GemInfo.each_compact_index_public_version(@ts).to_a

      assert_includes versions, CompactIndex::Gem.new("bar", [CompactIndex::GemVersion.new("1.0.0", "ruby", indexed_version.sha256, "v2yanked")])
      assert_equal GemInfo.compact_index_public_versions(@ts), versions
    end

    should "order gems by byte order, matching the previous gems.sort! behavior" do
      names = %w[Zzz aaa Mmm nnn]
      names.shuffle.each do |name|
        rubygem = create(:rubygem, name:)
        create(:version, rubygem:, number: "1.0.0", created_at: 10.minutes.ago, info_checksum_v2: "v2qw2dwe")
      end

      streamed_names = GemInfo.each_compact_index_public_version(@ts).map(&:name)
      relevant_names = streamed_names & names

      assert_equal names.sort, relevant_names
    end
  end
end
