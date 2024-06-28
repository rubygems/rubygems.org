require "test_helper"

class OwnershipCallPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = FactoryBot.create(:user)
    @rubygem = FactoryBot.create(:rubygem, owners: [@owner])
    @ownership_call = @rubygem.ownership_calls.create(user: @owner, note: "valid note")

    @user = FactoryBot.create(:user)
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
