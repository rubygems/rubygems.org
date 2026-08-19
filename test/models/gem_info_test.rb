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
end
