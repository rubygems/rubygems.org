# frozen_string_literal: true

require "test_helper"

class Api::V1::OIDC::PendingTrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  make_my_diffs_pretty!

  setup do
    create(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER)
  end

  context "without an API key" do
    should "deny index" do
      get api_v1_oidc_pending_trusted_publishers_path

      assert_response :unauthorized
    end

    should "deny create" do
      post api_v1_oidc_pending_trusted_publishers_path, params: {}

      assert_response :unauthorized
    end
  end

  context "with an account-scoped configure_trusted_publishers key" do
    setup do
      @api_key = create(:api_key, key: "12345", scopes: %i[configure_trusted_publishers])
    end

    context "on POST to create" do
      should "create a pending trusted publisher" do
        stub_request(:get, "https://api.github.com/users/example")
          .to_return(status: 200, body: { id: "123456" }.to_json, headers: { "Content-Type" => "application/json" })

        assert_difference -> { @api_key.user.oidc_pending_trusted_publishers.count }, 1 do
          post api_v1_oidc_pending_trusted_publishers_path,
               params: {
                 rubygem_name: "brand-new-gem",
                 trusted_publisher_type: "OIDC::TrustedPublisher::GitHubAction",
                 trusted_publisher: {
                   repository_owner: "example",
                   repository_name: "brand-new-gem",
                   workflow_filename: "push_gem.yml"
                 }
               },
               headers: { "HTTP_AUTHORIZATION" => "12345" }
        end

        assert_response :created
        pending = OIDC::PendingTrustedPublisher.find(response.parsed_body["id"])

        assert_equal "brand-new-gem", pending.rubygem_name
        assert_equal @api_key.user, pending.user
        assert_equal "example", pending.trusted_publisher.repository_owner
      end
    end
  end
end
