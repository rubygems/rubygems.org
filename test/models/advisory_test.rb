# frozen_string_literal: true

require "test_helper"

class AdvisoryTest < ActiveSupport::TestCase
  context "validations" do
    setup do
      @advisory = create(:advisory)
    end

    subject { @advisory }

    should validate_presence_of(:type)
    should validate_presence_of(:identifier)
    should validate_presence_of(:rubygem_name)
    should validate_presence_of(:summary)
    should validate_presence_of(:url)
    should validate_presence_of(:modified_at)
    should validate_uniqueness_of(:identifier).scoped_to(:type, :rubygem_name)
  end

  context "STI" do
    should "instantiate as Advisory::OSV" do
      advisory = create(:advisory)

      assert_instance_of Advisory::OSV, advisory
      assert_equal "Advisory::OSV", advisory.type
    end
  end

  context ".current" do
    should "exclude withdrawn advisories" do
      current = create(:advisory)
      create(:advisory, :withdrawn)

      assert_equal [current], Advisory.current.to_a
    end
  end

  context "rubygem association" do
    should "find the gem when it exists" do
      rubygem = create(:rubygem, name: "actionpack")
      advisory = create(:advisory, rubygem_name: "actionpack")

      assert_equal rubygem, advisory.rubygem
      assert_includes rubygem.advisories, advisory
    end

    should "allow an advisory when the gem does not exist" do
      advisory = build(:advisory, rubygem_name: "missing-gem")

      assert_predicate advisory, :valid?
      assert_nil advisory.rubygem
    end
  end

  context ".SOURCES" do
    should "include Advisory::OSV" do
      assert_includes Advisory::SOURCES, Advisory::OSV
    end
  end

  context ".feature_flag" do
    should "require subclasses to define feature_flag" do
      assert_raises(NotImplementedError) { Advisory.feature_flag }
    end
  end

  context ".enabled_sources" do
    should "exclude sources whose flag is off" do
      assert_empty Advisory.enabled_sources
    end

    should "include Advisory::OSV when its flag is on" do
      with_feature FeatureFlag::OSV_ADVISORIES do
        assert_equal [Advisory::OSV], Advisory.enabled_sources
      end
    end
  end

  context ".visible" do
    setup do
      @advisory = create(:advisory)
    end

    should "return none when no source flags are on" do
      assert_empty Advisory.visible
    end

    should "return current rows from enabled sources" do
      create(:advisory, :withdrawn)

      with_feature FeatureFlag::OSV_ADVISORIES do
        assert_equal [@advisory], Advisory.visible.to_a
      end
    end
  end

  context "#affects?" do
    should "return false when ranges are empty" do
      advisory = build(:advisory, ranges: [])

      refute advisory.affects?("1.0.0")
    end

    should "return false for an invalid version string" do
      advisory = build(:advisory, :range)

      refute advisory.affects?("not-a-version")
    end

    should "require subclasses to implement range matching" do
      assert_raises(NotImplementedError) do
        Advisory.new.send(:range_includes?, {}, Gem::Version.new("1.0.0"))
      end
    end
  end
end
