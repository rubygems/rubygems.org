# frozen_string_literal: true

require "test_helper"

class OIDC::RubygemTrustedPublisherPolicyTest < PolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @maintainer = create(:user, handle: "maintainer")
    @rubygem = create(:rubygem, owners: [@owner], maintainers: [@maintainer])
    @trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)

    @org_owner = create(:user, handle: "org_owner")
    @org_admin = create(:user, handle: "org_admin")
    @org_maintainer = create(:user, handle: "org_maintainer")
    @organization = create(:organization, owners: [@org_owner], admins: [@org_admin], maintainers: [@org_maintainer])
    @org_rubygem = create(:rubygem, name: "org_gem", organization: @organization, owners: [@owner], maintainers: [@maintainer])
    @org_trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @org_rubygem)

    @user = create(:user, handle: "user")
  end

  def policy!(user)
    Pundit.policy!(user, @trusted_publisher)
  end

  def org_policy!(user)
    Pundit.policy!(user, @org_trusted_publisher)
  end

  %i[show? create? destroy?].each do |action|
    context "##{action}" do
      should "only allow the owner" do
        assert_authorized policy!(@owner), action

        refute_authorized policy!(@maintainer), action
        refute_authorized policy!(@user), action
        refute_authorized policy!(nil), action
      end

      should "only allow owners, org owners and admins" do
        assert_authorized org_policy!(@org_owner), action
        assert_authorized org_policy!(@org_admin), action
        assert_authorized org_policy!(@owner), action

        refute_authorized org_policy!(@org_maintainer), action
        refute_authorized org_policy!(@maintainer), action
        refute_authorized org_policy!(@user), action
        refute_authorized org_policy!(nil), action
      end
    end
  end
end
