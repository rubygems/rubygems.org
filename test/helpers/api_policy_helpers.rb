require_relative "policy_helpers"

module ApiPolicyHelpers
  extend ActiveSupport::Concern
  include PolicyHelpers

  class_methods do
    def should_require_scope(scope, action)
      context "requires #{scope} scope" do
        should "deny ApiKey without scope" do
          refute_authorized key_without_scope(scope), action
        end

        should "allow ApiKey with scope" do
          assert_authorized key_with_scope(scope), action
        end
      end
    end

    def should_require_rubygem_scope(scope, action)
      context "requires #{scope} and matching rubygem" do
        should "deny ApiKey with rubygem without scope" do
          refute_authorized key_without_scope(scope, rubygem: @rubygem), action
        end

        should "deny ApiKey with scope but wrong rubygem" do
          refute_authorized key_with_scope(scope, rubygem: create(:rubygem, owners: [@owner])), action
        end

        should "allow ApiKey with scope and rubygem" do
          assert_authorized key_with_scope(scope, rubygem: @rubygem), action
        end
      end
    end

    def should_require_user_key(scope, action)
      context "requires ApiKey owned by a user" do
        should "deny ApiKey not owned by a user" do
          refute_authorized trusted_publisher_key(scope), action, I18n.t(:api_key_forbidden)
        end

        should "allow ApiKey owned by a user" do
          assert_authorized key_with_scope(scope), action
        end
      end
    end

    def should_require_mfa(scope, action)
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

    def should_delegate_to_policy(scope, action, policy_class)
      context "delegates to #{policy_class}##{action}" do
        should "allow if the #{policy_class} allows #{action}" do
          policy_class.any_instance.stubs(action => true)

          assert_authorized key_with_scope(scope), action
        end

        should "deny if the #{policy_class} denies #{action}" do
          policy_class.any_instance.stubs(action => false, :error => "error")

          refute_authorized key_with_scope(scope), action, "error"
        end
      end
    end
  end

  def trusted_publisher_key(scope)
    create(:api_key, :trusted_publisher, scopes: [scope])
  end

  def key_without_scope(scopes, **)
    scopes = (ApiKey::APPLICABLE_GEM_API_SCOPES - Array.wrap(scopes)).sample(2)
    key_with_scope(scopes, **)
  end

  def key_with_scope(scopes, owner: @owner, **)
    create(:api_key, owner:, scopes: Array.wrap(scopes), **)
  end

  def refute_authorized(actor, action, message = I18n.t(:api_key_insufficient_scope))
    super
  end
end
