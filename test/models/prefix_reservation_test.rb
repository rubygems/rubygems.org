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
      assert_includes prefix_reservation.errors[:prefix], "must be all lowercase"
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

    should "not treat an underscore in the prefix as a LIKE wildcard" do
      create(:prefix_reservation, prefix: "down_town")

      refute PrefixReservation.reserved?("downtown-mainstreet")
      assert PrefixReservation.reserved?("down_town-mainstreet")
    end
  end

  context "#permitted?" do
    setup do
      @organization = create(:organization)
      @prefix_reservation = create(:prefix_reservation, organization: @organization, prefix: "acme")
    end

    should "permit a gem that belongs to the organization" do
      assert @prefix_reservation.permitted?(build(:rubygem, name: "acme-widgets", organization: @organization))
    end

    should "permit a gem being pushed by a member of the organization" do
      rubygem = build(:rubygem, name: "acme-widgets")
      rubygem.pushed_by = create(:user).tap { create(:membership, user: it, organization: @organization) }

      assert @prefix_reservation.permitted?(rubygem)
    end

    should "permit a gem owned by a member of the organization" do
      member = create(:user)
      create(:membership, user: member, organization: @organization)

      assert @prefix_reservation.permitted?(create(:rubygem, name: "widgets", owners: [member]))
    end

    should "permit a name claimed by a pending trusted publisher belonging to a member" do
      member = create(:user)
      create(:membership, user: member, organization: @organization)
      create(:oidc_pending_trusted_publisher, user: member, rubygem_name: "acme-widgets")

      assert @prefix_reservation.permitted?(build(:rubygem, name: "acme-widgets"))
    end

    should "not permit a gem with no connection to the organization" do
      rubygem = build(:rubygem, name: "acme-widgets")
      rubygem.pushed_by = create(:user)

      refute @prefix_reservation.permitted?(rubygem)
    end

    should "not permit anything once the organization is deleted" do
      @organization.update!(deleted_at: Time.zone.now)

      refute @prefix_reservation.reload.permitted?(build(:rubygem, name: "acme-widgets"))
    end
  end
end
