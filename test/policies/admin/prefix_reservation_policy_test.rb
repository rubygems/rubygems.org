# frozen_string_literal: true

require "test_helper"

class Admin::PrefixReservationPolicyTest < AdminPolicyTestCase
  setup do
    @prefix_reservation = create(:prefix_reservation)
    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@prefix_reservation], policy_scope!(
      @admin,
      PrefixReservation
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, PrefixReservation, :avo_index?
    refute_authorizes @non_admin, PrefixReservation, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, PrefixReservation, :avo_show?
    refute_authorizes @non_admin, PrefixReservation, :avo_show?
  end

  def test_avo_create
    assert_authorizes @admin, PrefixReservation, :avo_create?
    refute_authorizes @non_admin, PrefixReservation, :avo_create?
  end

  def test_avo_destroy
    assert_authorizes @admin, PrefixReservation, :avo_destroy?
    refute_authorizes @non_admin, PrefixReservation, :avo_destroy?
  end

  def test_avo_search
    assert_authorizes @admin, PrefixReservation, :avo_search?
    refute_authorizes @non_admin, PrefixReservation, :avo_search?
  end

  def test_avo_update
    refute_authorizes @admin, PrefixReservation, :avo_update?
  end
end
