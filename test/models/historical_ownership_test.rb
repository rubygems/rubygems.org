# frozen_string_literal: true

require "test_helper"

class HistoricalOwnershipTest < ActiveSupport::TestCase
  should "be valid with factory" do
    assert_predicate build(:historical_ownership), :valid?
  end

  should belong_to :rubygem
  should belong_to :user
  should have_db_index %i[rubygem_id user_id]

  context "scopes" do
    setup do
      @current = create(:historical_ownership)
      @alumnus = create(:historical_ownership, :removed)
    end

    should "return only open records for .current" do
      assert_includes HistoricalOwnership.current, @current
      refute_includes HistoricalOwnership.current, @alumnus
    end

    should "return only closed records for .alumni" do
      assert_includes HistoricalOwnership.alumni, @alumnus
      refute_includes HistoricalOwnership.alumni, @current
    end

    should "exclude private records from .not_private" do
      private_ownership = create(:historical_ownership, private_at: Time.current)

      assert_includes HistoricalOwnership.not_private, @current
      refute_includes HistoricalOwnership.not_private, private_ownership
    end
  end

  context "#private?" do
    should "be false when private_at is nil" do
      refute_predicate build(:historical_ownership, private_at: nil), :private?
    end

    should "be true when private_at is set" do
      assert_predicate build(:historical_ownership, private_at: Time.current), :private?
    end
  end

  context "#make_private!" do
    should "set private_at when not already private" do
      historical_ownership = create(:historical_ownership, private_at: nil)
      historical_ownership.make_private!

      assert_predicate historical_ownership.reload, :private?
    end

    should "not touch an already-private record" do
      historical_ownership = create(:historical_ownership, private_at: 1.day.ago)

      assert_no_changes -> { historical_ownership.reload.private_at } do
        historical_ownership.make_private!
      end
    end
  end

  context "#make_public!" do
    should "clear private_at when private" do
      historical_ownership = create(:historical_ownership, private_at: Time.current)
      historical_ownership.make_public!

      refute_predicate historical_ownership.reload, :private?
    end

    should "not touch an already-public record" do
      historical_ownership = create(:historical_ownership, private_at: nil)

      assert_no_changes -> { historical_ownership.reload.updated_at } do
        historical_ownership.make_public!
      end
    end
  end
end
