require "test_helper"

class OwnershipPolicyTest < ActiveSupport::TestCase
  setup do
    @authorizer = FactoryBot.create(:user, handle: "owner")
    @maintainer = FactoryBot.create(:user, handle: "maintainer")
    @rubygem = FactoryBot.create(:rubygem, owners: [@authorizer], maintainers: [@maintainer])
    @authorizer_ownership = @rubygem.ownerships.first
    @maintainer_ownership = @maintainer.ownerships.first
    @unconfirmed_ownership = FactoryBot.build(:ownership, :unconfirmed, rubygem: @rubygem, authorizer: @authorizer)
    @unconfirmed_maintainer_ownership = FactoryBot.build(:ownership, :maintainer, rubygem: @rubygem, authorizer: @authorizer)

    @invited = @unconfirmed_ownership.user
    @user = FactoryBot.create(:user)
  end

  def test_create
    assert_predicate Pundit.policy!(@authorizer, @unconfirmed_ownership), :create?
    refute_predicate Pundit.policy!(@invited, @unconfirmed_ownership), :create?
    refute_predicate Pundit.policy!(@user, @unconfirmed_ownership), :create?
    refute_predicate Pundit.policy!(@maintainer, @maintainer_ownership), :create?
    refute_predicate Pundit.policy!(@maintainer, @unconfirmed_maintainer_ownership), :create?
  end

  def test_update
    assert_predicate Pundit.policy!(@authorizer, @maintainer_ownership), :update?
    refute_predicate Pundit.policy!(@authorizer, @authorizer_ownership), :update?
    refute_predicate Pundit.policy!(@invited, @unconfirmed_ownership), :update?
    refute_predicate Pundit.policy!(@user, @unconfirmed_ownership), :update?
    refute_predicate Pundit.policy!(@user, @unconfirmed_maintainer_ownership), :update?
    refute_predicate Pundit.policy!(@maintainer, @maintainer_ownership), :update?
    refute_predicate Pundit.policy!(@maintainer, @unconfirmed_maintainer_ownership), :update?
  end

  def test_destroy
    assert_predicate Pundit.policy!(@authorizer, @authorizer_ownership), :destroy?
    refute_predicate Pundit.policy!(@maintainer, @authorizer_ownership), :destroy?
    refute_predicate Pundit.policy!(@user, @authorizer_ownership), :destroy?
    refute_predicate Pundit.policy!(@user, @maintainer_ownership), :destroy?
    refute_predicate Pundit.policy!(@user, @unconfirmed_maintainer_ownership), :destroy?
  end
end
