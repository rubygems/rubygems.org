require "test_helper"

class Events::RubygemEventPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = FactoryBot.create(:user)
    @rubygem = FactoryBot.create(:rubygem, owners: [@owner])
    @event = @rubygem.events.last # rubygem:owner:added
    @user = FactoryBot.create(:user)
  end

  def test_show
    assert_predicate Pundit.policy!(@owner, @event), :show?
    refute_predicate Pundit.policy!(@user, @event), :show?
    refute_predicate Pundit.policy!(nil, @event), :show?
  end

  def test_create
    refute_predicate Pundit.policy!(@owner, Events::RubygemEvent), :create?
    refute_predicate Pundit.policy!(@user, Events::RubygemEvent), :create?
    refute_predicate Pundit.policy!(nil, Events::RubygemEvent), :create?
  end

  def test_update
    refute_predicate Pundit.policy!(@owner, @event), :update?
    refute_predicate Pundit.policy!(@user, @event), :update?
    refute_predicate Pundit.policy!(nil, @event), :update?
  end

  def test_destroy
    refute_predicate Pundit.policy!(@owner, @event), :destroy?
    refute_predicate Pundit.policy!(@user, @event), :destroy?
    refute_predicate Pundit.policy!(nil, @event), :destroy?
  end
end
