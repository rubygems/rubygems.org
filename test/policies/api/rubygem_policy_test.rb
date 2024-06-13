require "test_helper"

class Api::RubygemPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = create(:user)
    @rubygem = create(:rubygem, owners: [@owner])

    RubygemPolicy.any_instance.stubs(show_trusted_publishers?: true)
  end

  def policy!(api_key, rubygem = @rubygem)
    Pundit.policy!(api_key, [:api, rubygem])
  end

  context "#show_trusted_publishers?" do
    should "be false if the ApiKey scope does not include :configure_trusted_publishers" do
      api_key = create(:api_key, owner: @owner, scopes: %w[push_rubygem])

      refute_predicate policy!(api_key), :show_trusted_publishers?
    end

    should "be false if the ApiKey scope includes the rubygem but does not include :configure_trusted_publishers" do
      api_key = create(:api_key, owner: @owner, scopes: %w[push_rubygem], rubygem: @rubygem)

      refute_predicate policy!(api_key), :show_trusted_publishers?
    end

    should "be false if the ApiKey specifies a different rubygem" do
      other_gem = create(:rubygem, owners: [@owner])
      api_key = create(:api_key, owner: @owner, scopes: %w[configure_trusted_publishers], rubygem: other_gem)

      refute_predicate policy!(api_key), :show_trusted_publishers?
    end

    should "be false if the user policy for the gem does not allow show_trusted_publishers?" do
      RubygemPolicy.any_instance.stubs(show_trusted_publishers?: false)
      api_key = create(:api_key, owner: @owner, scopes: %w[configure_trusted_publishers])

      refute_predicate policy!(api_key), :show_trusted_publishers?
    end

    should "be true for ApiKey without rubygem" do
      api_key = create(:api_key, owner: @owner, scopes: %w[configure_trusted_publishers])

      assert_predicate policy!(api_key), :show_trusted_publishers?
    end

    should "be true for ApiKey with correct rubygem" do
      api_key = create(:api_key, owner: @owner, scopes: %w[configure_trusted_publishers], rubygem: @rubygem)

      assert_predicate policy!(api_key), :show_trusted_publishers?
    end
  end
end
