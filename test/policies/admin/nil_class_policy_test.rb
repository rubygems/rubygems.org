require "test_helper"

class Admin::NilClassPolicyTest < AdminPolicyTestCase
  def policy!(api_key)
    Pundit.policy!(api_key, [:api, nil])
  end

  context "::Scope.resolve" do
    should "raise" do
      assert_raises Pundit::NotDefinedError do
        Admin::NilClassPolicy::Scope.new(nil, nil).resolve
      end
    end
  end

  should "not authorize any avo action" do
    refute_authorizes nil, nil, :avo_index?
    refute_authorizes nil, nil, :avo_show?
    refute_authorizes nil, nil, :avo_create?
    refute_authorizes nil, nil, :avo_new?
    refute_authorizes nil, nil, :avo_update?
    refute_authorizes nil, nil, :avo_edit?
    refute_authorizes nil, nil, :avo_destroy?
    refute_authorizes nil, nil, :act_on?
    refute_authorizes nil, nil, :avo_search?
  end
end
