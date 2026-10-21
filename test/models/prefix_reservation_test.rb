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

    should belong_to(:organization).optional

    should "save without an organization" do
      assert_predicate create(:prefix_reservation, organization: nil), :persisted?
    end

    should "reject an organization_id that doesn't exist" do
      assert_raises(ActiveRecord::InvalidForeignKey) do
        create(:prefix_reservation, organization_id: Organization.maximum(:id).to_i + 1)
      end
    end

    should "validate downcase" do
      prefix_reservation = build(:prefix_reservation, prefix: "ABX")

      refute_predicate prefix_reservation, :valid?
      assert_includes prefix_reservation.errors[:prefix], "must be all lowercase"
    end
  end

  context "with an existing prefix reservation" do
    setup do
      @organization = create(:organization, handle: "acme-corp")
      create(:prefix_reservation, organization: @organization, prefix: "acme")
    end

    should "reject a longer prefix that starts with the existing prefix" do
      prefix_reservation = build(:prefix_reservation, prefix: "acme-corp")

      refute_predicate prefix_reservation, :valid?
      assert_includes prefix_reservation.errors[:prefix], "overlaps the existing 'acme' reservation for the acme-corp organization"
    end

    should "reject a shorter prefix that the existing prefix starts with" do
      prefix_reservation = build(:prefix_reservation, prefix: "acm")

      refute_predicate prefix_reservation, :valid?
      assert_includes prefix_reservation.errors[:prefix], "overlaps the existing 'acme' reservation for the acme-corp organization"
    end

    should "reject an overlapping prefix for the same organization" do
      refute_predicate build(:prefix_reservation, organization: @organization, prefix: "acme-widgets"), :valid?
    end

    should "allow a prefix that only shares leading characters" do
      assert_predicate build(:prefix_reservation, prefix: "acne"), :valid?
    end

    should "not treat an underscore as a wildcard when checking overlap" do
      create(:prefix_reservation, prefix: "down_town")

      assert_predicate build(:prefix_reservation, prefix: "downtown"), :valid?
    end

    should "not report an existing reservation as overlapping itself" do
      assert_predicate PrefixReservation.find_by!(prefix: "acme"), :valid?
    end

    should "still reject an overlap after the existing reservation's organization is deleted" do
      @organization.update!(deleted_at: Time.zone.now)
      prefix_reservation = build(:prefix_reservation, prefix: "acme-corp")

      refute_predicate prefix_reservation, :valid?
      assert_includes prefix_reservation.errors[:prefix], "overlaps the existing 'acme' reservation"
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
      @member = create(:user)
      create(:membership, user: @member, organization: @organization)
      @prefix_reservation = create(:prefix_reservation, organization: @organization, prefix: "acme")
    end

    should "permit a new gem a member claims for the organization" do
      assert @prefix_reservation.permitted?(claimed_rubygem(organization: @organization, by: @member))
    end

    should "not permit a new gem a member claims for another organization" do
      refute @prefix_reservation.permitted?(claimed_rubygem(organization: create(:organization), by: @member))
    end

    should "not permit a new gem a member pushes without claiming the organization" do
      rubygem = build(:rubygem, name: "acme-widgets")
      rubygem.pushed_by = @member

      refute @prefix_reservation.permitted?(rubygem)
    end

    should "not permit a new gem a non-member claims for the organization" do
      refute @prefix_reservation.permitted?(claimed_rubygem(organization: @organization, by: create(:user)))
    end

    should "not permit a new gem claimed by an unconfirmed member" do
      pending_member = create(:user)
      create(:membership, :pending, user: pending_member, organization: @organization)

      refute @prefix_reservation.permitted?(claimed_rubygem(organization: @organization, by: pending_member))
    end

    should "not permit a new gem that only sets the organization without a claiming member" do
      refute @prefix_reservation.permitted?(build(:rubygem, name: "acme-widgets", organization: @organization))
    end

    should "permit renaming a gem that already belongs to the organization" do
      assert @prefix_reservation.permitted?(create(:rubygem, name: "widgets", organization: @organization))
    end

    should "not permit renaming a gem owned by a member outside the organization" do
      refute @prefix_reservation.permitted?(create(:rubygem, name: "widgets", owners: [@member]))
    end

    should "not permit anything once the organization is deleted" do
      rubygem = claimed_rubygem(organization: @organization, by: @member)
      @organization.update!(deleted_at: Time.zone.now)

      refute @prefix_reservation.reload.permitted?(rubygem)
    end
  end

  context "#conflict_message" do
    setup do
      @organization = create(:organization, handle: "acme-corp")
      @prefix_reservation = create(:prefix_reservation, organization: @organization, prefix: "acme")
    end

    should "name the organization and tell its admins how to claim the gem" do
      assert_equal "'acme-widgets' starts with 'acme', a prefix reserved by the acme-corp organization. " \
                   "If you are an admin of acme-corp, add `spec.metadata[\"rubygems_organization\"] = \"acme-corp\"` " \
                   "to your gemspec to push it to the organization.",
                   @prefix_reservation.conflict_message("acme-widgets")
    end

    should "omit the organization once it is deleted" do
      @organization.update!(deleted_at: Time.zone.now)

      assert_equal "'acme-widgets' starts with 'acme', a reserved prefix.",
                   @prefix_reservation.reload.conflict_message("acme-widgets")
    end
  end

  private

  def claimed_rubygem(organization:, by:)
    build(:rubygem, name: "acme-widgets").tap do |rubygem|
      rubygem.claim_for_organization(organization, by:)
    end
  end
end
