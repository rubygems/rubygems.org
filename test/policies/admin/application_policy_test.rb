require "test_helper"

class Admin::ApplicationPolicyTest < AdminPolicyTestCase
  should "onle inherit from Admin::ApplicationPolicy in Admin:: namespace" do
    Admin.constants.each do |const|
      next if const == :ApplicationPolicy
      next unless const.to_s.end_with?("Policy")

      klass = Admin.const_get(const)

      assert_operator klass, :<, Admin::ApplicationPolicy, "#{const} does not inherit from Admin::ApplicationPolicy"
      assert_operator klass::Scope, :<, Admin::ApplicationPolicy::Scope, "#{const}::Scope does not inherit from Admin::ApplicationPolicy::Scope"
    end
  end
end
