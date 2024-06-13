require "test_helper"

class OwnershipCallPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = FactoryBot.create(:user)
    @rubygem = FactoryBot.create(:rubygem, owners: [@owner])
    @ownership_call = @rubygem.ownership_calls.create(user: @owner, note: "valid note")

    @user = FactoryBot.create(:user)
  end

  def test_scope
    # Tests that nothing is returned currently because scope is unused
    assert_empty Pundit.policy_scope!(@authorizer, OwnershipCall).to_a
    assert_empty Pundit.policy_scope!(@invited, OwnershipCall).to_a
    assert_empty Pundit.policy_scope!(@user, OwnershipCall).to_a
  end

  def test_create
    assert_predicate Pundit.policy!(@owner, @ownership_call), :create?
    refute_predicate Pundit.policy!(@user, @ownership_call), :create?
  end

  def test_destroy
    assert_predicate Pundit.policy!(@owner, @ownership_call), :close?
    refute_predicate Pundit.policy!(@user, @ownership_call), :close?
  end
end
