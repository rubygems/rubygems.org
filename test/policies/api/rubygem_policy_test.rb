require "test_helper"

class Api::RubygemPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user, handle: "owner")
    @rubygem = create(:rubygem, owners: [@owner])

    RubygemPolicy.any_instance.stubs(
      configure_trusted_publishers?: true,
      add_owner?: true,
      remove_owner?: true
    )
  end

  def policy!(api_key, rubygem = @rubygem)
    Pundit.policy!(api_key, [:api, rubygem])
  end

  def key_without_scope(scope, rubygem = nil)
    scopes = (ApiKey::APPLICABLE_GEM_API_SCOPES - [scope]).sample(2)
    create(:api_key, owner: @owner, scopes: scopes, rubygem:)
  end

  def key_with_scope(scope, rubygem = nil)
    create(:api_key, owner: @owner, scopes: [scope], rubygem:)
  end

  context "#index?" do
    setup do
      @action = :index?
      @scope = :index_rubygems
    end

    should "deny ApiKey without scope" do
      refute_predicate policy!(key_without_scope(@scope)), @action
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
