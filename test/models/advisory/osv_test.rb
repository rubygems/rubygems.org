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
end
