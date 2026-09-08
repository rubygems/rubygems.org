# frozen_string_literal: true

require "test_helper"

class RubygemTransferTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @rubygem = create(:rubygem)
    @organization = create(:organization)
    @transfer = create(:rubygem_transfer, created_by: @owner, rubygems: [@rubygem.id], organization: @organization)
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

    @transfer.invites.create!(user: user, invitable: @transfer, role: :outside_contributor)
    @transfer.transfer!

    assert_includes @rubygem.reload.owners, user
  end

  test "updating invites when rubygems change" do
    maintainer = create(:user)
    other_rubygem = create(:rubygem, owners: [@owner], maintainers: [maintainer])

    assert_empty @transfer.invites

    @transfer.rubygems = [other_rubygem.id]
    @transfer.save

    assert_includes @transfer.invites.map(&:user), maintainer
  end

  test "validates rubygem ownership before transfer" do
    non_owner = create(:user)
    @transfer.created_by = non_owner

    assert_not @transfer.valid?
    assert_includes @transfer.errors[:created_by], "must be an owner of the #{@rubygem.name} gem"
    assert_includes @transfer.errors[:created_by], "does not have permission to transfer gems to this organization"
  end

  test "sets the organization for each rubygem" do
    @transfer.transfer!

    assert_equal @organization, @rubygem.reload.organization
  end

  test "creating memberships from invites" do
    invites = build_list(:organization_invite, 2, invitable: @transfer, role: :owner)
    @transfer.invites << invites
    @transfer.transfer!

    invites.each do |invite|
      assert Membership.exists?(user: invite.user, organization: @organization, role: invite.role)
    end
  end

  test "not creating memberships for invites without a specified role" do
    invites = build_list(:organization_invite, 2, invitable: @transfer, role: nil)
    @transfer.invites << invites
    @transfer.transfer!

    invites.each do |invite|
      assert_not Membership.exists?(user: invite.user, organization: @organization)
    end
  end

  test "demote outside contributors from owner to maintainer role" do
    user = create(:user)
    ownership = create(:ownership, rubygem: @rubygem, user: user, role: :owner)

    @transfer.invites.create!(user: user, invitable: @transfer, role: :outside_contributor)
    @transfer.transfer!

    ownership.reload

    assert_equal "maintainer", ownership.role
  end

  test "keep outside contributors with maintainer role unchanged" do
    user = create(:user)
    ownership = create(:ownership, rubygem: @rubygem, user: user, role: :maintainer)

    @transfer.invites.create!(user: user, invitable: @transfer, role: :outside_contributor)
    @transfer.transfer!

    ownership.reload

    assert_equal "maintainer", ownership.role
  end

  test "not create organization membership for outside contributors" do
    user = create(:user)
    create(:ownership, rubygem: @rubygem, user: user, role: :owner)

    @transfer.invites.create!(user: user, invitable: @transfer, role: :outside_contributor)
    @transfer.transfer!

    assert_not Membership.exists?(user: user, organization: @organization)
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
    assert_includes @transfer.errors[:rubygems], "#{@rubygem.name} is already owned by an organization"
  end

  test "skips existing members instead of creating a duplicate or changing their role" do
    co_owner = create(:user)
    create(:ownership, rubygem: @rubygem, user: co_owner, role: :owner)
    membership = create(:membership, :maintainer, user: co_owner, organization: @organization)
    @transfer.invites.create!(user: co_owner, role: :admin)

    OrganizationMailer.expects(:user_invited).never

    assert_no_difference -> { Membership.unscoped.where(organization: @organization).count } do
      @transfer.transfer!
    end

    assert_predicate @transfer, :completed?
    assert_equal "maintainer", membership.reload.role
    assert_not Ownership.exists?(user: co_owner, rubygem: @rubygem)
    assert_equal @organization, @rubygem.reload.organization
  end

  test "removes ownership for existing members even when invite is outside contributor" do
    co_owner = create(:user)
    create(:ownership, rubygem: @rubygem, user: co_owner, role: :owner)
    membership = create(:membership, :admin, user: co_owner, organization: @organization)
    @transfer.invites.create!(user: co_owner, role: :outside_contributor)

    @transfer.transfer!

    assert_equal "admin", membership.reload.role
    assert_not Ownership.exists?(user: co_owner, rubygem: @rubygem)
  end

  test "creates membership for new invitee and leaves existing member unchanged" do
    existing_member = create(:user)
    new_invitee = create(:user)
    create(:ownership, rubygem: @rubygem, user: existing_member, role: :owner)
    create(:ownership, rubygem: @rubygem, user: new_invitee, role: :owner)
    membership = create(:membership, :maintainer, user: existing_member, organization: @organization)
    @transfer.invites.create!(user: existing_member, role: :owner)
    @transfer.invites.create!(user: new_invitee, role: :admin)

    OrganizationMailer.expects(:user_invited).once.returns(stub(deliver_later: true))

    assert_difference -> { Membership.unscoped.where(organization: @organization).count }, 1 do
      @transfer.transfer!
    end

    assert_equal "maintainer", membership.reload.role
    assert Membership.exists?(user: new_invitee, organization: @organization, role: :admin)
    assert_not Ownership.exists?(user: existing_member, rubygem: @rubygem)
    assert_not Ownership.exists?(user: new_invitee, rubygem: @rubygem)
  end

  test "removes ownership for existing members even without an invite role" do
    co_owner = create(:user)
    create(:ownership, rubygem: @rubygem, user: co_owner, role: :owner)
    membership = create(:membership, :admin, user: co_owner, organization: @organization)
    @transfer.invites.create!(user: co_owner, role: nil)

    @transfer.transfer!

    assert_equal "admin", membership.reload.role
    assert_not Ownership.exists?(user: co_owner, rubygem: @rubygem)
  end

  test "does not review existing organization members on the users step" do
    co_owner = create(:user)
    outsider = create(:user)
    other_rubygem = create(:rubygem, owners: [@owner, co_owner, outsider])
    create(:membership, :admin, user: co_owner, organization: @organization)

    @transfer.rubygems = [other_rubygem.id]
    @transfer.save!

    reviewable_user_ids = @transfer.reviewable_invites.map(&:user_id)

    assert_includes reviewable_user_ids, outsider.id
    assert_not_includes reviewable_user_ids, co_owner.id
  end
end
