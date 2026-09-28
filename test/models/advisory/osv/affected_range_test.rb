# frozen_string_literal: true

require "test_helper"

class Advisory::OSV::AffectedRangeTest < ActiveSupport::TestCase
  context "#include?" do
    should "match an inclusive introduced and exclusive fixed bound" do
      affected = affected_range(introduced: "1.0.0", fixed: "1.2.0")

      refute_includes affected, version("0.9.0")
      assert_includes affected, version("1.0.0")
      assert_includes affected, version("1.1.9")
      refute_includes affected, version("1.2.0")
    end

    should "match an inclusive last_affected bound" do
      affected = affected_range(introduced: "1.0.0", last_affected: "1.0.0")

      refute_includes affected, version("0.9.0")
      assert_includes affected, version("1.0.0")
      refute_includes affected, version("1.0.1")
    end

    should "treat introduced 0 as an unbounded lower bound" do
      affected = affected_range(introduced: "0")

      assert_includes affected, version("0.0.1")
      assert_includes affected, version("99.0.0")
    end

    should "prefer fixed over last_affected when both are present" do
      affected = affected_range(introduced: "1.0.0", fixed: "1.2.0", last_affected: "1.1.0")

      assert_includes affected, version("1.1.5")
      refute_includes affected, version("1.2.0")
    end

    should "treat a range with only introduced as still affected" do
      affected = affected_range(introduced: "2.0.0")

      refute_includes affected, version("1.9.0")
      assert_includes affected, version("2.0.0")
      assert_includes affected, version("9.0.0")
    end

    should "skip a range with an invalid bound" do
      affected = affected_range(introduced: "1.0.0", fixed: "not-a-version")

      refute_includes affected, version("1.0.0")
    end
  end

  context "#as_json" do
    should "omit nil bounds" do
      assert_equal({ "introduced" => "2.0.0" }, affected_range(introduced: "2.0.0").as_json)
    end
  end

  private

  def affected_range(introduced: nil, fixed: nil, last_affected: nil)
    Advisory::OSV::AffectedRange.new(introduced:, fixed:, last_affected:)
  end

  def version(number)
    Gem::Version.new(number)
  end
end
