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
      @membership.update!(role: Access::OWNER)
      assert_authorized @user, :update?
    end

    should "return false if user is not an owner" do
      @membership.update!(role: Access::MAINTAINER)
      refute_authorized @user, :update?
    end
  end
end
