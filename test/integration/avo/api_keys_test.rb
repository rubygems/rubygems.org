# frozen_string_literal: true

require "test_helper"

class Avo::ApiKeysTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  setup { requires_avo_pro }

  test "showing the revoke action to rubygems.org operators on the API key page" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    api_key = create(:api_key, name: "compromised-deploy-key")

    get avo.resources_api_key_path(api_key)

    assert_response :success
    assert_select "a[data-action-name='Revoke API Key'][data-disabled='false']", count: 1
  end

  test "disabling the revoke action for an expired API key" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    api_key = create(:api_key, name: "expired-deploy-key")
    api_key.update_column(:expires_at, 1.hour.ago)

    get avo.resources_api_key_path(api_key)

    assert_response :success
    assert page.has_content?("Revoke API Key — #{Avo::Actions::RevokeApiKey.already_revoked_reason}")
    assert_select "a[data-action-name^='Revoke API Key'][data-disabled='true']", count: 1
  end
end
