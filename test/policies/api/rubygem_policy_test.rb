require "test_helper"

class Api::RubygemPolicyTest < ActiveSupport::TestCase
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

  def policy
    @policy ||= Pundit.policy!(@api_key, [:api, @rubygem])
  end

  def trusted_publisher_key
    trusted_publisher = create(:oidc_trusted_publisher_github_action)
    create(:api_key, key: "tp", owner: trusted_publisher)
  end

  def key_without_scope(scope, rubygem = nil)
    scopes = (ApiKey::APPLICABLE_GEM_API_SCOPES - [scope]).sample(2)
    create(:api_key, owner: @owner, scopes: scopes, rubygem:)
  end

  def key_with_scope(scope, rubygem = nil)
    create(:api_key, owner: @owner, scopes: [scope], rubygem:)
  end

  def refute_authorized(policy, action, message = nil)
    refute_predicate policy, action
    assert_equel message, policy.error if message
  end

  context "#index?" do
    setup do
      @action = :index?
      @scope = :index_rubygems
    end

    should "deny ApiKey without scope" do
      refute_authorized policy!(key_without_scope(@scope)), @action, "You do not have permission to access this gem."
    end

    should "allow ApiKey with scope" do
      assert_predicate policy!(key_with_scope(@scope)), @action
    end
  end

  context "#create?" do
    setup do
      @action = :create?
      @scope = :push_rubygem
    end

    should "deny ApiKey without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with rubygem without scope" do
      refute_predicate policy!(key_without_scope(@scope, @rubygem)), @action
    end

    should "allow ApiKey with scope" do
      assert_predicate policy!(key_with_scope(@scope)), @action
    end
  end

  context "#yank?" do
    setup do
      @action = :yank?
      @scope = :yank_rubygem
    end

    should "deny ApiKey without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with rubygem without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with scope wrong rubygem" do
      refute_predicate policy!(key_with_scope(@scope, create(:rubygem, owners: [@owner]))), @action
    end

    should "allow ApiKey with scope" do
      assert_predicate policy!(key_with_scope(@scope)), @action
    end

    should "allow ApiKey with scope and rubygem" do
      assert_predicate policy!(key_with_scope(@scope, @rubygem)), @action
    end
  end

  context "#configure_trusted_publishers?" do
    setup do
      @action = :configure_trusted_publishers?
      @scope = :configure_trusted_publishers
    end

    should "deny ApiKey without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with rubygem without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with scope wrong rubygem" do
      refute_predicate policy!(key_with_scope(@scope, create(:rubygem, owners: [@owner]))), @action
    end

    should "allow ApiKey with scope" do
      assert_predicate policy!(key_with_scope(@scope)), @action
    end

    should "allow ApiKey with scope and rubygem" do
      assert_predicate policy!(key_with_scope(@scope, @rubygem)), @action
    end
  end

  context "#add_owner" do
    setup do
      @action = :add_owner?
      @scope = :add_owner
    end

    should "deny ApiKey not owned by a user" do
      refute_predicate policy!(trusted_publisher_key), @action
    end

    should_require_mfa(:add_owner?)
    context "mfa required" do
      setup do
        GemDownload.increment(Rubygem::MFA_REQUIRED_THRESHOLD + 1, rubygem_id: @rubygem.id)
        @rubygem.reload
      end

      should "be false if the user does not have MFA enabled" do
        refute_predicate policy!(key_with_scope(@scope)), @action
      end

      should "be false if the user has MFA enabled but the request includes incorrect MFA credentials" do
        assert_predicate @owner, :mfa_required_not_yet_enabled?

        refute_predicate policy!(key_with_scope(@scope)), @action
      end

      should "deny ApiKey with owner.mfa_required_weak_level_enabled?" do
        @owner.enable_totp!(ROTP::Base32.random_base32, :ui_only)

        assert_predicate @owner, :mfa_required_weak_level_enabled?
        refute_predicate policy!(key_with_scope(@scope)), @action
      end
    end

    should "be false if the base RubygemPolicy for the gem does not allow add_owner?" do
      RubygemPolicy.any_instance.stubs(add_owner?: false)
      @api_key = create(:api_key, owner: @owner, scopes: %w[add_owner])

      refute_predicate policy!(key_with_scope(@scope)), @action

      refute_predicate policy, :add_owner?
    end

    should "deny ApiKey without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with rubygem without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with scope wrong rubygem" do
      refute_predicate policy!(key_with_scope(@scope, create(:rubygem, owners: [@owner]))), @action
    end

    should "allow ApiKey with scope" do
      assert_predicate policy!(key_with_scope(@scope)), @action
    end

    should "allow ApiKey with scope and rubygem" do
      assert_predicate policy!(key_with_scope(@scope, @rubygem)), @action
    end
  end

  context "#remove_owner" do
    setup do
      @action = :remove_owner?
      @scope = :remove_owner
    end

    should "deny ApiKey without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with rubygem without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
    end

    should "deny ApiKey with scope wrong rubygem" do
      refute_predicate policy!(key_with_scope(@scope, create(:rubygem, owners: [@owner]))), @action
    end

    should "allow ApiKey with scope" do
      assert_predicate policy!(key_with_scope(@scope)), @action
    end

    should "allow ApiKey with scope and rubygem" do
      assert_predicate policy!(key_with_scope(@scope, @rubygem)), @action
    end
  end
end
