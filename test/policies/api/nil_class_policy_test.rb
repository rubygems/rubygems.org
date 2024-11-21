require "test_helper"

class Api::NilClassPolicyTest < ApiPolicyTestCase
  def policy!(api_key)
    Pundit.policy!(api_key, [:api, nil])
  end

  context "::Scope.resolve" do
    should "raise" do
      assert_raises Pundit::NotDefinedError do
        Api::NilClassPolicy::Scope.new(nil, nil).resolve
      end
    end
  end

  context "#destroy?" do
    should "not be authorized" do
      refute_authorized policy!(nil), :destroy?, "Forbidden"
    end
  end
end
