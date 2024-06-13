require "test_helper"

class Api::OIDC::RubygemTrustedPublisherPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @rubygem = create(:rubygem, owners: [@owner])
    @trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)

    OIDC::RubygemTrustedPublisherPolicy.any_instance.stubs(show?: true, create?: true, destroy?: true)
  end

  def policy!(api_key, record = @trusted_publisher)
    Pundit.policy!(api_key, [:api, record])
  end

  def refute_authorized(api_key)
    refute_predicate policy!(api_key), :show?
    refute_predicate policy!(api_key), :create?
    refute_predicate policy!(api_key), :destroy?
  end

  def assert_authorized(api_key)
    assert_predicate policy!(api_key), :show?
    assert_predicate policy!(api_key), :create?
    assert_predicate policy!(api_key), :destroy?
  end

  should "be false if the ApiKey scope does not include :configure_trusted_publishers" do
    api_key = create(:api_key, owner: @owner, scopes: %w[push_rubygem])

    refute_authorized api_key
  end

  should "be false if the ApiKey scope includes the rubygem but does not include :configure_trusted_publishers" do
    api_key = create(:api_key, owner: @owner, scopes: %w[push_rubygem], rubygem: @rubygem)

    refute_authorized api_key
  end

  should "be false if the ApiKey specifies a different rubygem" do
    other_gem = create(:rubygem, owners: [@owner])
    api_key = create(:api_key, owner: @owner, scopes: %w[configure_trusted_publishers], rubygem: other_gem)

    refute_authorized api_key
  end

  should "be false if the user policy for the gem does not allow show_trusted_publishers?" do
    OIDC::RubygemTrustedPublisherPolicy.any_instance.stubs(show?: false, create?: false, destroy?: false)
    api_key = create(:api_key, owner: @owner, scopes: %w[configure_trusted_publishers])

    refute_authorized api_key
  end

  should "be true for ApiKey without rubygem" do
    api_key = create(:api_key, owner: @owner, scopes: %w[configure_trusted_publishers])

    assert_authorized api_key
  end

  should "be true for ApiKey with correct rubygem" do
    api_key = create(:api_key, owner: @owner, scopes: %w[configure_trusted_publishers], rubygem: @rubygem)

    assert_authorized api_key
  end
end
