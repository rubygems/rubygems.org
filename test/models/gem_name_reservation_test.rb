require "test_helper"

class GemNameReservationTest < ActiveSupport::TestCase
  context "with a saved reservation" do
    setup do
      @reservation = create(:gem_name_reservation)
    end

    subject { @reservation }

    should_not allow_value(nil).for(:name)
    should_not allow_value("").for(:name)
    should_not allow_value("Abc").for(:name)
    should allow_value("abc").for(:name)
    should validate_uniqueness_of(:name).case_insensitive
  end

  context "#reserved?" do
    should "recognize reserved gem name" do
      create(:gem_name_reservation, name: "reserved-gem-name")
      GemNameReservation.reserved?("reserved-gem-name")
    end

    should "recognize reserved case insensitive gem name" do
      create(:gem_name_reservation, name: "reserved-gem-name")
      GemNameReservation.reserved?("RESERVED-gem-name")
    end

    should "recognize not reserved gem name" do
      GemNameReservation.reserved?("totally-random-gem-name")
    end
  end
end
