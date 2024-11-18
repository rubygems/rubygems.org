require "test_helper"

class Api::RubygemPolicyTest < ApiPolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @rubygem = create(:rubygem, owners: [@owner])

    RubygemPolicy.any_instance.stubs(
      configure_trusted_publishers?: true,
      add_owner?: true,
      remove_owner?: true
    )
  end

  def policy!(api_key)
    Pundit.policy!(api_key, [:api, @rubygem])
  end

  context "#index?" do
    scope = :index_rubygems
    action = :index?

    should_require_scope scope, action

    should "allow ApiKey with scope and any rubygem" do
      api_key = key_with_scope([:push_rubygem, scope], rubygem: create(:rubygem, owners: [@owner]))

      assert_authorized api_key, action
    end
  end

  context "#create?" do
    scope = :push_rubygem
    action = :create?

    should_require_scope scope, action
    should_require_mfa scope, action

    should "deny ApiKey without scope but with rubygem" do
      refute_authorized key_without_scope(:push_rubygem, rubygem: @rubygem), :create?
    end
  end

  context "#yank?" do
    scope = :yank_rubygem
    action = :yank?

    should_require_user_key scope, action
    should_require_scope scope, action
    should_require_rubygem_scope scope, action
  end

  context "#configure_trusted_publishers?" do
    scope = :configure_trusted_publishers
    action = :configure_trusted_publishers?

    should_require_user_key scope, action
    should_require_mfa scope, action
    should_require_scope scope, action
    should_require_rubygem_scope scope, action
    should_delegate_to_policy scope, action, RubygemPolicy
  end

  context "#add_owner" do
    scope = :add_owner
    action = :add_owner?

    should_require_user_key scope, action
    should_require_mfa scope, action
    should_require_scope scope, action
    should_require_rubygem_scope scope, action
    should_delegate_to_policy scope, action, RubygemPolicy
  end

  context "#remove_owner" do
    scope = :remove_owner
    action = :remove_owner?

    should_require_user_key scope, action
    should_require_mfa scope, action
    should_require_scope scope, action
    should_require_rubygem_scope scope, action
    should_delegate_to_policy scope, action, RubygemPolicy
  end
end
