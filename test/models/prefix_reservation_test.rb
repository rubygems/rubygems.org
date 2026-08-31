# frozen_string_literal: true

require "test_helper"

class PrefixReservationTest < ActiveSupport::TestCase
  context "with a saved prefix reservation" do
    setup do
      @prefix_reservation = build(:prefix_reservation)
    end

    subject { @prefix_reservation }

    should_not allow_value(nil).for(:prefix)
    should_not allow_value("").for(:prefix)
    should_not allow_value("a").for(:prefix)

    should validate_uniqueness_of(:prefix).case_insensitive

    should validate_length_of(:prefix).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_length_of(:prefix).is_at_least(3)

    should "validate downcase" do
      prefix_reservation = build(:prefix_reservation, prefix: "ABX")

      refute_predicate prefix_reservation, :valid?
      assert prefix_reservation.errors[:prefix], "must be all lowercase"
    end
  end

  context "#reserved?" do
    should "return true if the input is a match to an existing prefix" do
      create(:prefix_reservation, prefix: "downtown")

      assert PrefixReservation.reserved?("downtown-mainstreet")
      assert PrefixReservation.reserved?("downtown_mainstreet")
      assert PrefixReservation.reserved?("downtownmainstreet")
      assert PrefixReservation.reserved?("DOWNTOWN-mainstreet")

      refute PrefixReservation.reserved?("downtow-mainstreet") # misspelling
    end
  end
end
