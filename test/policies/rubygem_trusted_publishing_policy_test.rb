require "test_helper"

class RubygemTrustedPublishingPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @maintainer = create(:user, handle: "maintainer")
    @user = create(:user, handle: "user")
    @rubygem = create(:rubygem, owners: [@owner], maintainers: [@maintainer])
    @rubygem_trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)
  end

  def policy!(user)
    Pundit.policy!(user, @rubygem_trusted_publisher)
  end

  context "#show?" do
    should "only allow the owner" do
      assert_authorized @owner, :show?
      refute_authorized @maintainer, :show?
      refute_authorized @user, :show?
      refute_authorized nil, :show?
    end
  end

  context "create?" do
    should "only allow the owner" do
      assert_authorized @owner, :create?
      refute_authorized @maintainer, :create?
      refute_authorized @user, :create?
      refute_authorized nil, :create?
    end
  end

  context "#destroy?" do
    should "only allow the owner" do
      assert_authorized @owner, :destroy?
      refute_authorized @maintainer, :destroy?
      refute_authorized @user, :destroy?
      refute_authorized nil, :destroy?
    end
  end
end
