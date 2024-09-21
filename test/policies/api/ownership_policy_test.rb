require "test_helper"

class Api::OwnershipPolicyTest < ApiPolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @user = create(:user, handle: "user")
    @rubygem = create(:rubygem, owners: [@owner])

    @record = create(:ownership, rubygem: @rubygem, user: @user, authorizer: @owner)

    OwnershipPolicy.any_instance.stubs(
      update?: true,
      destroy?: true
    )
  end

  def policy!(api_key)
    Pundit.policy!(api_key, [:api, @record])
  end

  context "#update?" do
    scope = :update_owner
    action = :update?

    should_require_user_key scope, action
    should_require_mfa scope, action
    should_require_scope scope, action
    should_require_rubygem_scope scope, action
    should_delegate_to_policy scope, action, OwnershipPolicy
  end
end
