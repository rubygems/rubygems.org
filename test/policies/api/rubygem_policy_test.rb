require "test_helper"

class Api::RubygemPolicyTest < ApiPolicyTestCase
  setup do
    @user = create(:user, handle: "user")
    @owner = create(:user, handle: "owner")
    @rubygem = create(:rubygem, owners: [@owner])

    RubygemPolicy.any_instance.stubs(
      configure_trusted_publishers?: true,
      add_owner?: true,
      remove_owner?: true
    )
  end

  def record = @rubygem

  def trusted_publisher_key(scope)
    create(:api_key, :trusted_publisher, key: "tp", scopes: [scope])
  end

  def key_without_scope(scope, rubygem = nil)
    scopes = (ApiKey::APPLICABLE_GEM_API_SCOPES - [scope]).sample(2)
    create(:api_key, owner: @owner, scopes: scopes, rubygem:)
  end

  def key_with_scope(scope, rubygem = nil)
    create(:api_key, owner: @owner, scopes: [scope], rubygem:)
  end

  def self.should_require_scope(scope, action)
    should "deny ApiKey without scope" do
      refute_authorized key_without_scope(scope), action
    end

    should "allow ApiKey with scope" do
      assert_authorized key_with_scope(scope), action
    end
  end

  def self.should_require_rubygem_scope(scope, action)
    should "deny ApiKey with rubygem without scope" do
      refute_authorized key_without_scope(scope, @rubygem), action
    end

    should "deny ApiKey with scope but wrong rubygem" do
      refute_authorized key_with_scope(scope, create(:rubygem, owners: [@owner])), action
    end

    should "allow ApiKey with scope and rubygem" do
      assert_authorized key_with_scope(scope, @rubygem), action
    end
  end

  def self.should_require_user_key(scope, action)
    should "deny ApiKey not owned by a user" do
      refute_authorized trusted_publisher_key(scope), action, I18n.t(:api_key_forbidden)
    end
  end

  def self.should_require_mfa(scope, action)
    context "mfa required" do
      setup do
        GemDownload.increment(Rubygem::MFA_REQUIRED_THRESHOLD + 1, rubygem_id: @rubygem.id)
        @rubygem.reload
      end

      should "deny ApiKey with owner.mfa_required_not_yet_enabled?" do
        assert_predicate @owner, :mfa_required_not_yet_enabled?
        refute_authorized key_with_scope(scope), action, I18n.t("multifactor_auths.api.mfa_required_not_yet_enabled")
      end

      should "deny ApiKey with owner.mfa_required_weak_level_enabled?" do
        @owner.enable_totp!(ROTP::Base32.random_base32, :ui_only)

        assert_predicate @owner, :mfa_required_weak_level_enabled?
        refute_authorized key_with_scope(scope), action, I18n.t("multifactor_auths.api.mfa_required_weak_level_enabled")
      end

      should "allow ApiKey with strong level mfa" do
        @owner.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

        assert_predicate @owner, :strong_mfa_level?
        assert_authorized key_with_scope(scope), action
      end
    end
  end

  def self.should_delegate_to_user_policy(scope, action)
    should "be true if the base RubygemPolicy for the gem allows add_owner?" do
      RubygemPolicy.any_instance.stubs(action => true)

      assert_authorized key_with_scope(scope), action
    end

    should "be false if the base RubygemPolicy for the gem does not allow add_owner?" do
      RubygemPolicy.any_instance.stubs(action => false, :error => "error")

      refute_authorized key_with_scope(scope), action, "error"
    end
  end

  context "#index?" do
    should_require_scope :index_rubygems, :index?
  end

  context "#create?" do
    scope = :push_rubygem
    action = :create?

    should_require_scope scope, action
    should_require_mfa scope, action

    should "deny ApiKey with rubygem without scope" do
      refute_authorized key_without_scope(:push_rubygem, @rubygem), :create?
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
    should_delegate_to_user_policy scope, action
  end

  context "#add_owner" do
    scope = :add_owner
    action = :add_owner?

    should_require_user_key scope, action
    should_require_mfa scope, action
    should_require_scope scope, action
    should_require_rubygem_scope scope, action
    should_delegate_to_user_policy scope, action
  end

  context "#remove_owner" do
    scope = :remove_owner
    action = :remove_owner?

    should_require_user_key scope, action
    should_require_mfa scope, action
    should_require_scope scope, action
    should_require_rubygem_scope scope, action
    should_delegate_to_user_policy scope, action
  end
end
