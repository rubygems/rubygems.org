require "test_helper"

class Admin::GeoipInfoPolicyTest < AdminPolicyTestCase
  setup do
    @geoip_info = create(:geoip_info)

    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@geoip_info], policy_scope!(
      @admin,
      GeoipInfo
    ).to_a
  end

  def test_avo_index
    assert_predicate policy!(@admin, GeoipInfo), :avo_index?
    refute_predicate policy!(@non_admin, GeoipInfo), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @geoip_info), :avo_show?
    refute_predicate policy!(@non_admin, @geoip_info), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, GeoipInfo), :avo_create?
    refute_predicate policy!(@non_admin, GeoipInfo), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @geoip_info), :avo_update?
    refute_predicate policy!(@non_admin, @geoip_info), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @geoip_info), :avo_destroy?
    refute_predicate policy!(@non_admin, @geoip_info), :avo_destroy?
  end
end
