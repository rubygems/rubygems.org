require "test_helper"

class RubygemPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = FactoryBot.create(:user)
    @rubygem = FactoryBot.create(:rubygem, owners: [@owner])
    @user = FactoryBot.create(:user)
  end

  def test_scope
    # Tests that nothing is returned currently because scope is unused
    assert_empty Pundit.policy_scope!(@owner, Rubygem).to_a
    assert_empty Pundit.policy_scope!(@user, Rubygem).to_a
  end

  def test_show
    assert_predicate Pundit.policy!(@owner, @rubygem), :show?
    assert_predicate Pundit.policy!(nil, @rubygem), :show?
  end

  def test_show_unconfirmed_ownerships?
    assert_predicate Pundit.policy!(@owner, @rubygem), :show_unconfirmed_ownerships?
    refute_predicate Pundit.policy!(@user, @rubygem), :show_unconfirmed_ownerships?
    refute_predicate Pundit.policy!(nil, @rubygem), :show_unconfirmed_ownerships?
  end

  def test_show_events?
    assert_predicate Pundit.policy!(@owner, @rubygem), :show_events?
    refute_predicate Pundit.policy!(@user, @rubygem), :show_events?
    refute_predicate Pundit.policy!(nil, @rubygem), :show_events?
  end

  def test_create
    assert_predicate Pundit.policy!(@owner, @rubygem), :create?
    refute_predicate Pundit.policy!(nil, @rubygem), :create?
  end

  def test_update
    refute_predicate Pundit.policy!(@owner, @rubygem), :update?
    refute_predicate Pundit.policy!(nil, @rubygem), :update?
  end

  def test_destroy
    refute_predicate Pundit.policy!(@owner, @rubygem), :destroy?
    refute_predicate Pundit.policy!(nil, @rubygem), :destroy?
  end
end
