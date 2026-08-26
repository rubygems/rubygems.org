# frozen_string_literal: true

require "test_helper"

class Advisory::OSVTest < ActiveSupport::TestCase
  context "validations" do
    setup do
      @advisory = create(:advisory)
    end

    subject { @advisory }

    should define_enum_for(:severity)
      .with_values(low: "low", moderate: "moderate", high: "high", critical: "critical")
      .backed_by_column_of_type(:string)
  end

  context ".feature_flag" do
    should "use the OSV advisories flag" do
      assert_equal FeatureFlag::OSV_ADVISORIES, Advisory::OSV.feature_flag
    end
  end

  context "severity" do
    should "accept each severity value and allow nil" do
      %w[low moderate high critical].each do |severity|
        advisory = build(:advisory, severity: severity)

        assert_predicate advisory, :valid?
      end

      advisory = build(:advisory, severity: nil)

      assert_predicate advisory, :valid?
    end

    should "reject an unknown severity" do
      advisory = build(:advisory, severity: "severe")

      refute_predicate advisory, :valid?
      assert_includes advisory.errors[:severity], "is not included in the list"
    end
  end

  context "#affects?" do
    should "match an inclusive introduced and exclusive fixed range" do
      advisory = build(:advisory, :range)

      refute advisory.affects?("0.9.0")
      assert advisory.affects?("1.0.0")
      assert advisory.affects?("1.1.9")
      refute advisory.affects?("1.2.0")
    end

    should "match an exact last_affected version" do
      advisory = build(:advisory, :exact)

      refute advisory.affects?("0.9.0")
      assert advisory.affects?("1.0.0")
      refute advisory.affects?("1.0.1")
    end

    should "treat introduced 0 as an unbounded lower bound" do
      advisory = build(:advisory, :unfixed)

      assert advisory.affects?("0.0.1")
      assert advisory.affects?("99.0.0")
    end

    should "prefer fixed over last_affected when both are present" do
      advisory = build(:advisory, ranges: ["introduced" => "1.0.0", "fixed" => "1.2.0", "last_affected" => "1.1.0"])

      assert advisory.affects?("1.1.5")
      refute advisory.affects?("1.2.0")
    end

    should "match any of multiple ranges" do
      advisory = build(:advisory, ranges: [
                         { "introduced" => "5.2.0", "fixed" => "5.2.7.1" },
                         { "introduced" => "6.0.0", "last_affected" => "6.0.4.7" }
                       ])

      assert advisory.affects?("5.2.3")
      refute advisory.affects?("5.2.7.1")
      assert advisory.affects?("6.0.4.7")
      refute advisory.affects?("6.0.4.8")
      refute advisory.affects?("5.1.0")
    end

    should "accept a Version object" do
      version = build(:version, number: "1.1.0")
      advisory = build(:advisory, :range)

      assert advisory.affects?(version)
    end

    should "skip a range with an invalid bound" do
      advisory = build(:advisory, ranges: ["introduced" => "1.0.0", "fixed" => "not-a-version"])

      refute advisory.affects?("1.0.0")
    end

    should "treat a range with only introduced as still affected" do
      advisory = build(:advisory, ranges: ["introduced" => "2.0.0"])

      refute advisory.affects?("1.9.0")
      assert advisory.affects?("2.0.0")
      assert advisory.affects?("9.0.0")
    end
  end
end
