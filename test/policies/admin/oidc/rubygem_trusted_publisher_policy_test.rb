require "test_helper"

class Admin::OIDC::RubygemTrustedPublisherPolicyTest < AdminPolicyTestCase
  setup do
    @rubygem_trusted_publisher = create(:oidc_rubygem_trusted_publisher)

    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@rubygem_trusted_publisher], policy_scope!(
      @admin,
      OIDC::RubygemTrustedPublisher
    ).to_a
  end

  def test_avo_index
    assert_predicate policy!(@admin, OIDC::RubygemTrustedPublisher), :avo_index?
    refute_predicate policy!(@non_admin, OIDC::RubygemTrustedPublisher), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @rubygem_trusted_publisher), :avo_show?
    refute_predicate policy!(@non_admin, @rubygem_trusted_publisher), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, OIDC::RubygemTrustedPublisher), :avo_create?
    refute_predicate policy!(@non_admin, OIDC::RubygemTrustedPublisher), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @rubygem_trusted_publisher), :avo_update?
    refute_predicate policy!(@non_admin, @rubygem_trusted_publisher), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @rubygem_trusted_publisher), :avo_destroy?
    refute_predicate policy!(@non_admin, @rubygem_trusted_publisher), :avo_destroy?
  end
end
