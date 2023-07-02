require "test_helper"

class GemNameReservationTest < ActiveSupport::TestCase
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
