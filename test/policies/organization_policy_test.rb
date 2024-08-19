require "test_helper"

class OrganisationPolicyTest < PolicyTestCase
  setup do
    @user = create(:user)
    @organization = create(:organization)
    @membership = create(:membership, user: @user, organization: @organization)
  end

  def policy!(user)
    Pundit.policy!(user, @organization)
  end

  context "#update?" do
    should "return true if user is an owner" do
      @membership.update!(role: :owner)
      assert_authorized @user, :update?
    end

    should "return false if user is not an owner" do
      @membership.update!(role: :maintainer)
      refute_authorized @user, :update?
    end
  end

  context "add_gem?" do
    should "return true is the user is an admin" do
      @membership.update!(role: :owner)
      assert_authorized @user, :add_gem?
    end

    should "retrun false is the user is not an owner" do
      @membership.update!(role: :maintainer)
      refute_authorized @user, :add_gem?
    end
  end

  context "#remove_gem?" do
    should "return true is the user is an admin" do
      @membership.update!(role: :owner)
      assert_authorized @user, :remove_gem?
    end

    should "return false is the user is not an admin" do
      @membership.update!(role: :maintainer)
      refute_authorized @user, :remove_gem?
    end
  end
end
