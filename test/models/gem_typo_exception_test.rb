# frozen_string_literal: true

require "test_helper"

class GemTypoExceptionTest < ActiveSupport::TestCase
  context "name validations" do
    should validate_uniqueness_of(:name).case_insensitive
    should validate_length_of(:name).is_at_most(Gemcutter::MAX_FIELD_LENGTH)

    should "be a valid factory" do
      assert_predicate build(:gem_typo_exception), :valid?
    end

    should "be invalid with an empty string" do
      exception = build(:gem_typo_exception, name: "")

      refute_predicate exception, :valid?
    end

    should "be invalid when gem name exists" do
      create(:rubygem, name: "some")

      exception = build(:gem_typo_exception, name: "some")

      refute_predicate exception, :valid?
    end
  end

  context "with a prefix reservation" do
    setup do
      @organization = create(:organization, handle: "acme-corp")
      create(:prefix_reservation, organization: @organization, prefix: "acme")
    end

    should "be invalid for a name under the reserved prefix" do
      exception = build(:gem_typo_exception, name: "acme-widgetz")

      assert_no_difference -> { GemTypoException.count } do
        refute exception.save
      end
      assert_match(/'acme-widgetz' starts with 'acme', a prefix reserved by the acme-corp organization/,
        exception.errors[:name].join)
    end

    should "be invalid for a name under the reserved prefix in a different case" do
      exception = build(:gem_typo_exception, name: "Acme_Widgetz")

      refute_predicate exception, :valid?
    end

    should "be invalid for a name under a prefix reserved without an organization" do
      PrefixReservation.destroy_all
      create(:prefix_reservation, organization: nil, prefix: "acme")
      exception = build(:gem_typo_exception, name: "acme-widgetz")

      refute_predicate exception, :valid?
      assert_match(/'acme-widgetz' starts with 'acme', a reserved prefix\./, exception.errors[:name].join)
    end

    should "be valid for a name outside the reserved prefix" do
      exception = build(:gem_typo_exception, name: "acm-widgetz")

      assert_predicate exception, :valid?
    end
  end
end
