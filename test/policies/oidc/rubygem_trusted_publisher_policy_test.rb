require "test_helper"

class OIDC::RubygemTrustedPublisherPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = FactoryBot.create(:user)
    @rubygem = FactoryBot.create(:rubygem, owners: [@owner])
    @trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)
    @user = FactoryBot.create(:user)
  end

  def test_scope
    assert_empty Pundit.policy_scope!(@owner, OIDC::RubygemTrustedPublisher).to_a
    assert_empty Pundit.policy_scope!(@owner, @rubygem.oidc_rubygem_trusted_publishers).to_a
  end

  def test_show
    assert_predicate Pundit.policy!(@owner, @trusted_publisher), :show?
    refute_predicate Pundit.policy!(@user, @trusted_publisher), :show?
    refute_predicate Pundit.policy!(nil, @trusted_publisher), :show?
  end

  def test_create
    assert_predicate Pundit.policy!(@owner, @trusted_publisher), :create?
    refute_predicate Pundit.policy!(@user, @trusted_publisher), :create?
    refute_predicate Pundit.policy!(nil, @trusted_publisher), :create?
  end

  def test_destroy
    assert_predicate Pundit.policy!(@owner, @trusted_publisher), :destroy?
    refute_predicate Pundit.policy!(@user, @trusted_publisher), :destroy?
    refute_predicate Pundit.policy!(nil, @trusted_publisher), :destroy?
  end
end
