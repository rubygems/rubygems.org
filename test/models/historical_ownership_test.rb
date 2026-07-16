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
      assert_not_includes HistoricalOwnership.current, @alumnus
    end

    should "return only closed records for .alumni" do
      assert_includes HistoricalOwnership.alumni, @alumnus
      assert_not_includes HistoricalOwnership.alumni, @current
    end
  end
end
