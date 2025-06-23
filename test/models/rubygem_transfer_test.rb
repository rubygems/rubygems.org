require "test_helper"

class RubygemTransferTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @rubygem = create(:rubygem, owners: [@owner])
    @organization = create(:organization, owners: [@owner])
    @transfer = create(:rubygem_transfer, created_by: @owner, rubygem: @rubygem, organization: @organization)
  end

  test "record errors when transfer fails" do
    @transfer.stubs(:transaction).raises(ActiveRecord::ActiveRecordError, "ActiveRecord error")

    assert_raises(ActiveRecord::ActiveRecordError) do
      @transfer.transfer!
    end

    assert_predicate @transfer, :failed?
    assert_predicate @transfer.error, :present?
    assert_nil @rubygem.reload.organization
  end

  test "removing previous owners from the rubygem" do
    @transfer.transfer!

    assert_empty Ownership.where(rubygem: @rubygem)
  end

  test "not removing owners who are given the outside contributor role" do
    user = create(:user)
    create(:ownership, rubygem: @rubygem, user: user, role: :owner)

    @transfer.invites.create!(user: user, principal: @transfer, role: :outside_contributor)
    @transfer.transfer!

    assert_includes @rubygem.reload.owners, user
  end

  test "validates rubygem ownership before transfer" do
    non_owner = create(:user)
    @transfer.created_by = non_owner

    assert_not @transfer.valid?
    assert_includes @transfer.errors[:rubygem], "does not have permission to transfer this gem"
    assert_includes @transfer.errors[:organization], "does not have permission to transfer gems to this organization"
  end

  test "sets the organization for the rubygem" do
    @transfer.transfer!

    assert_equal @organization, @rubygem.reload.organization
  end

  test "creating memberships from invites" do
    invites = build_list(:organization_induction, 2, principal: @transfer, role: :owner)
    @transfer.invites << invites
    @transfer.transfer!

    invites.each do |invite|
      assert Membership.exists?(user: invite.user, organization: @organization, role: invite.role)
    end
  end

  test "not creating memberships for invites without a specified role" do
    invites = build_list(:organization_induction, 2, principal: @transfer, role: nil)
    @transfer.invites << invites
    @transfer.transfer!

    invites.each do |invite|
      assert_not Membership.exists?(user: invite.user, organization: @organization)
    end
  end

  test "updates the status and completed_at fields when transfer is successful" do
    @transfer.transfer!

    assert_predicate @transfer, :completed?
    assert_predicate @transfer.completed_at, :present?
  end

  test "not allowing transfer if rubygem already has an organization" do
    existing_organization = create(:organization)
    @rubygem.update!(organization: existing_organization)

    assert_not @transfer.valid?
    assert_includes @transfer.errors[:rubygem], "is already owned by an organization"
  end
end
