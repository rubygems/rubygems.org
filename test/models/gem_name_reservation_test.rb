# frozen_string_literal: true

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
    should validate_length_of(:name).is_at_most(Gemcutter::MAX_FIELD_LENGTH)

    should "for an organization reservation not save when there's an existing rubygem with the same name " do
      organization = create(:organization)
      create(:rubygem, name: "bounce-haus")

      reservation = build(:gem_name_reservation, name: "bounce-haus", organization:)

      refute reservation.save
    end

    should "reservation save when there's an existing rubygem with the same name " do
      create(:rubygem, name: "bounce-haus")

      reservation = build(:gem_name_reservation, name: "bounce-haus")

      assert reservation.save
    end

    should "not save when there's an existing rubygem with the case matched name" do
      create(:rubygem, name: "bounce-haus")

      reservation = build(:gem_name_reservation, name: "BoUnCe-HAaus")

      refute reservation.save
    end
  end

  context "organization reservation limit" do
    setup do
      @organization = create(:organization)
    end

    should "allow reserving up to the limit" do
      create_list(:gem_name_reservation, GemNameReservation::ORGANIZATION_LIMIT - 1, organization: @organization)

      assert_predicate build(:gem_name_reservation, organization: @organization), :valid?
    end

    should "not allow reserving beyond the limit" do
      create_list(:gem_name_reservation, GemNameReservation::ORGANIZATION_LIMIT, organization: @organization)

      reservation = build(:gem_name_reservation, organization: @organization)

      refute_predicate reservation, :valid?
      assert_equal ["Your organization has reached its limit of 25 reserved gem names."], reservation.errors.full_messages
    end

    should "allow reserving beyond the limit when the feature flag is enabled for the organization" do
      create_list(:gem_name_reservation, GemNameReservation::ORGANIZATION_LIMIT, organization: @organization)

      with_feature(FeatureFlag::UNLIMITED_GEM_NAME_RESERVATIONS, actor: @organization) do
        assert_predicate build(:gem_name_reservation, organization: @organization), :valid?
      end
    end

    should "not count another organization's reservations toward the limit" do
      create_list(:gem_name_reservation, GemNameReservation::ORGANIZATION_LIMIT, organization: create(:organization))

      assert_predicate build(:gem_name_reservation, organization: @organization), :valid?
    end

    should "not limit reservations without an organization" do
      create_list(:gem_name_reservation, GemNameReservation::ORGANIZATION_LIMIT)

      assert_predicate build(:gem_name_reservation), :valid?
    end

    should "not block renaming an existing reservation for an organization at the limit" do
      create_list(:gem_name_reservation, GemNameReservation::ORGANIZATION_LIMIT - 1, organization: @organization)
      reservation = create(:gem_name_reservation, organization: @organization)

      assert reservation.update(name: "some-other-name")
    end

    should "not allow moving a reservation into an organization at the limit" do
      create_list(:gem_name_reservation, GemNameReservation::ORGANIZATION_LIMIT, organization: @organization)
      reservation = create(:gem_name_reservation)

      refute reservation.update(organization: @organization)
    end
  end

  context "#reserved?" do
    should "recognize reserved gem name" do
      create(:gem_name_reservation, name: "reserved-gem-name")

      assert GemNameReservation.reserved?("reserved-gem-name")
    end

    should "recognize reserved case insensitive gem name" do
      create(:gem_name_reservation, name: "reserved-gem-name")

      assert GemNameReservation.reserved?("RESERVED-gem-name")
    end

    should "recognize not reserved gem name" do
      refute GemNameReservation.reserved?("totally-random-gem-name")
    end
  end
end
