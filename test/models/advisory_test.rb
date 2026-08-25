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
end
