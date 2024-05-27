require "test_helper"

class Admin::GemNameReservationPolicyTest < AdminPolicyTestCase
  setup do
    @scope = create(:gem_name_reservation)
    @admin = create(:admin_github_user, :is_admin)
  end

  def test_scope
    assert_equal [@scope], policy_scope!(
      @admin,
      GemNameReservation
    ).to_a
  end

  def test_avo_index
    assert_predicate policy!(@admin, GemNameReservation), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, GemNameReservation), :avo_show?
  end

  def test_avo_create
    assert_predicate policy!(@admin, GemNameReservation), :avo_create?
  end

  def test_avo_destroy
    assert_predicate policy!(@admin, GemNameReservation), :avo_destroy?
  end

  def test_avo_search
    assert_predicate policy!(@admin, GemNameReservation), :avo_search?
  end

  def test_avo_update
    refute_predicate policy!(@admin, GemNameReservation), :avo_update?
  end
end
