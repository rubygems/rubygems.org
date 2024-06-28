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

  context "#create?" do
    should "allow the requester to create when the gem is considered abandoned" do
      assert_predicate Pundit.policy!(@requester, @ownership_request), :create?
      refute_predicate Pundit.policy!(@owner, @ownership_request), :create?
      refute_predicate Pundit.policy!(@user, @ownership_request), :create?
    end

    should "not allow the requester to create when the gem is not considered abandoned" do
      newgem = create(:rubygem, number: "1.0", owners: [@owner])
      newgem_request = build(:ownership_request, rubygem: newgem, user: @requester)

      refute_predicate Pundit.policy!(@requester, newgem_request), :create?
      refute_predicate Pundit.policy!(@owner, newgem_request), :create?
      refute_predicate Pundit.policy!(@user, newgem_request), :create?
    end
  end

  context "#approve?" do
    should "only allow the owner to approve" do
      refute_predicate Pundit.policy!(@requester, @ownership_request), :approve?
      assert_predicate Pundit.policy!(@owner, @ownership_request), :approve?
      refute_predicate Pundit.policy!(@user, @ownership_request), :approve?
    end
  end

  context "#close?" do
    should "allow the requester to close" do
      assert_predicate Pundit.policy!(@requester, @ownership_request), :close?
    end

    should "allow the owner to close" do
      assert_predicate Pundit.policy!(@owner, @ownership_request), :close?
    end

    should "not allow other users to close" do
      refute_predicate Pundit.policy!(@user, @ownership_request), :close?
    end
  end
end
