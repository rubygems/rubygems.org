# frozen_string_literal: true

require "test_helper"

class Api::OIDC::ApiKeyRolePolicyTest < ApiPolicyTestCase
  setup do
    @owner = create(:user, handle: "owner")
    @rubygem = create(:rubygem, owners: [@owner])
  end

  def policy!(api_key)
    Pundit.policy!(api_key, [:api, OIDC::ApiKeyRole])
  end

  %i[index? show?].each do |action|
    context "##{action}" do
      scope = :access_oidc_api_key_roles

      should_require_user_key scope, action
      should_require_scope scope, action
      should_require_account_wide_scope scope, action

      should "deny ApiKey with only the index_rubygems scope" do
        refute_authorized key_with_scope(:index_rubygems), action
      end

      should "deny ApiKey with only the show_dashboard scope" do
        refute_authorized key_with_scope(:show_dashboard), action
      end

      should "deny ApiKey with only the configure_trusted_publishers scope" do
        refute_authorized key_with_scope(:configure_trusted_publishers), action
      end
    end
  end
end
