# frozen_string_literal: true

require "test_helper"
require "compact_index"
require "helpers/compact_index_helpers"

class CompactIndex::GemVersionTest < ActiveSupport::TestCase
  include CompactIndexHelpers

  context "#<=>" do
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

  context "#to_line" do
    should "not include created_at for v1" do
      v = build_version(number: "1.0")

      assert_equal "1.0 |checksum:sum+test_gem+1.0", v.to_line
    end

    should "not include created_at for v2 when absent" do
      v = build_version(version: 2, number: "1.0")

      assert_equal "1.0 |checksum:sum+test_gem+1.0", v.to_line
    end

    should "include created_at for v2 when present" do
      v = build_version(version: 2, number: "1.0", created_at: "2026-05-12T10:00:00Z")

      assert_equal "1.0 |checksum:sum+test_gem+1.0,created_at:2026-05-12T10:00:00Z", v.to_line
    end
  end
end
