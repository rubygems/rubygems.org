require "test_helper"

class Admin::OIDC::RubygemTrustedPublisherPolicyTest < ActiveSupport::TestCase
  setup do
    @rubygem_trusted_publisher = create(:oidc_rubygem_trusted_publisher)

    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@rubygem_trusted_publisher], Pundit.policy_scope!(
      @admin,
      OIDC::RubygemTrustedPublisher
    ).to_a
  end

  def test_avo_index
    assert_predicate Pundit.policy!(@admin, OIDC::RubygemTrustedPublisher), :avo_index?
    refute_predicate Pundit.policy!(@non_admin, OIDC::RubygemTrustedPublisher), :avo_index?
  end

  def test_avo_show
    assert_predicate Pundit.policy!(@admin, @rubygem_trusted_publisher), :avo_show?
    refute_predicate Pundit.policy!(@non_admin, @rubygem_trusted_publisher), :avo_show?
  end

  def test_avo_create
    refute_predicate Pundit.policy!(@admin, OIDC::RubygemTrustedPublisher), :avo_create?
    refute_predicate Pundit.policy!(@non_admin, OIDC::RubygemTrustedPublisher), :avo_create?
  end

  def test_avo_update
    refute_predicate Pundit.policy!(@admin, @rubygem_trusted_publisher), :avo_update?
    refute_predicate Pundit.policy!(@non_admin, @rubygem_trusted_publisher), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Pundit.policy!(@admin, @rubygem_trusted_publisher), :avo_destroy?
    refute_predicate Pundit.policy!(@non_admin, @rubygem_trusted_publisher), :avo_destroy?
  end
end
