require "test_helper"
class MembershipPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @admin = create(:user, handle: "admin")
    @maintainer = create(:user, handle: "maintainer")
    @guest = create(:user)
    @organization = create(:organization, owners: [@owner], admins: [@admin], maintainers: [@maintainer])
  end

  def policy!(user, record = Membership)
    Pundit.policy!(user, record)
  end

  context "#create?" do
    context "adding an owner" do
      should "be authorized for org owners only" do
        membership = build(:membership, :owner, organization: @organization)

        assert_authorized policy!(@owner, membership), :create?

        refute_authorized policy!(@admin, membership), :create?
        refute_authorized policy!(@maintainer, membership), :create?
        refute_authorized policy!(@guest, membership), :create?
      end
    end

    context "adding an admin" do
      should "be authorized for org admins and owners" do
        membership = build(:membership, :admin, organization: @organization)

        assert_authorized policy!(@owner, membership), :create?
        assert_authorized policy!(@admin, membership), :create?

        refute_authorized policy!(@maintainer, membership), :create?
        refute_authorized policy!(@guest, membership), :create?
      end
    end
  end

  context "#update?" do
    context "changing to owner" do
      should "be authorized for org owners only" do
        membership = create(:membership, :admin, organization: @organization)
        membership.role = :owner

        assert_authorized policy!(@owner, membership), :update?

        refute_authorized policy!(@admin, membership), :update?
        refute_authorized policy!(@maintainer, membership), :update?
        refute_authorized policy!(@guest, membership), :update?
      end
    end

    context "changing from owner" do
      should "be authorized for org owners only" do
        membership = create(:membership, :owner, organization: @organization)
        membership.role = :admin

        assert_authorized policy!(@owner, membership), :update?

        refute_authorized policy!(@admin, membership), :update?
        refute_authorized policy!(@maintainer, membership), :update?
        refute_authorized policy!(@guest, membership), :update?
      end
    end

    context "changing from admin" do
      should "be authorized for org admins and owners" do
        membership = create(:membership, :admin, organization: @organization)
        membership.role = :maintainer

        assert_authorized policy!(@owner, membership), :update?
        assert_authorized policy!(@admin, membership), :update?

        refute_authorized policy!(@maintainer, membership), :update?
        refute_authorized policy!(@guest, membership), :update?
      end
    end

    context "changing to admin" do
      should "be authorized for org admins and owners" do
        membership = create(:membership, :maintainer, organization: @organization)
        membership.role = :admin

        assert_authorized policy!(@owner, membership), :update?
        assert_authorized policy!(@admin, membership), :update?

        refute_authorized policy!(@maintainer, membership), :update?
        refute_authorized policy!(@guest, membership), :update?
      end
    end
  end

  context "#destroy?" do
    context "removing owner" do
      should "be authorized for org owners only" do
        membership = create(:membership, :owner, organization: @organization)

        assert_authorized policy!(@owner, membership), :destroy?

        refute_authorized policy!(@admin, membership), :destroy?
        refute_authorized policy!(@maintainer, membership), :destroy?
        refute_authorized policy!(@guest, membership), :destroy?
      end
    end

    context "removing admin" do
      should "be authorized for org admins and owners" do
        membership = create(:membership, :admin, organization: @organization)

        assert_authorized policy!(@owner, membership), :destroy?
        assert_authorized policy!(@admin, membership), :destroy?

        refute_authorized policy!(@maintainer, membership), :destroy?
        refute_authorized policy!(@guest, membership), :destroy?
      end
    end
  end
end
