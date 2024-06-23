require "test_helper"

class OwnershipRequestPolicyTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, handle: "user")
    @owner = create(:user, handle: "owner")
    @requester = create(:user, handle: "requester")

    @rubygem = create(:rubygem, number: "1.0", owners: [@owner], created_at: 2.years.ago)
    @rubygem.versions.last.update!(created_at: 2.years.ago)

    # ensure it is possible to request ownership of the rubygem
    assert_predicate Pundit.policy!(@requester, @rubygem), :request_ownership?
    @ownership_request = create(:ownership_request, rubygem: @rubygem, user: @requester)
  end

  def test_scope
    assert_empty Pundit.policy_scope!(@owner, OwnershipCall).to_a
    assert_empty Pundit.policy_scope!(@owner, @rubygem.ownership_requests).to_a
    assert_empty Pundit.policy_scope!(@requester, OwnershipCall).to_a
    assert_empty Pundit.policy_scope!(@user, OwnershipCall).to_a
  end

  def test_create
    assert_predicate Pundit.policy!(@requester, @ownership_request), :create?
    refute_predicate Pundit.policy!(@owner, @ownership_request), :create?
    refute_predicate Pundit.policy!(@user, @ownership_request), :create?

    newgem = create(:rubygem, number: "1.0", owners: [@owner])
    newgem_request = build(:ownership_request, rubygem: newgem, user: @requester)

    refute_predicate Pundit.policy!(@requester, newgem_request), :create?
    refute_predicate Pundit.policy!(@owner, newgem_request), :create?
    refute_predicate Pundit.policy!(@user, newgem_request), :create?
  end

  def test_approve
    refute_predicate Pundit.policy!(@requester, @ownership_request), :approve?
    assert_predicate Pundit.policy!(@owner, @ownership_request), :approve?
    refute_predicate Pundit.policy!(@user, @ownership_request), :approve?
  end

  def test_close
    assert_predicate Pundit.policy!(@requester, @ownership_request), :close?
    assert_predicate Pundit.policy!(@owner, @ownership_request), :close?
    refute_predicate Pundit.policy!(@user, @ownership_request), :close?
  end
end
