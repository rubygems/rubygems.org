require "test_helper"

class OwnershipPolicyTest < ActiveSupport::TestCase
  setup do
    @authorizer = FactoryBot.create(:user)
    @rubygem = FactoryBot.create(:rubygem, owners: [@authorizer])
    @confirmed_ownership = @rubygem.ownerships.first
    @unconfirmed_ownership = FactoryBot.build(:ownership, :unconfirmed, rubygem: @rubygem, authorizer: @authorizer)

    @invited = @unconfirmed_ownership.user
    @user = FactoryBot.create(:user)
  end

  def test_create
    assert_predicate Pundit.policy!(@authorizer, @unconfirmed_ownership), :create?
    refute_predicate Pundit.policy!(@invited, @unconfirmed_ownership), :create?
    refute_predicate Pundit.policy!(@user, @unconfirmed_ownership), :create?
  end

  def test_destroy
    assert_predicate Pundit.policy!(@authorizer, @confirmed_ownership), :destroy?
    refute_predicate Pundit.policy!(@owner, @confirmed_ownership), :destroy?
    refute_predicate Pundit.policy!(@user, @confirmed_ownership), :destroy?
  end
end
