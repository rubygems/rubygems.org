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

        # Contract the CLI depends on: nested trusted_publisher object in the response body.
        assert_predicate response.parsed_body["id"], :present?
        assert_equal "brand-new-gem", response.parsed_body["rubygem_name"]
        nested = response.parsed_body["trusted_publisher"]

        assert_kind_of Hash, nested
        assert_equal "example", nested["repository_owner"]
        assert_equal "brand-new-gem", nested["repository_name"]
        assert_equal "push_gem.yml", nested["workflow_filename"]
      end
    end

    context "on POST to create with an existing pushable gem name" do
      should "return 422" do
        stub_request(:get, "https://api.github.com/users/example")
          .to_return(status: 200, body: { id: "123456" }.to_json, headers: { "Content-Type" => "application/json" })
        rubygem = create(:rubygem, name: "already-exists")
        create(:version, rubygem: rubygem)
        post api_v1_oidc_pending_trusted_publishers_path,
             params: { rubygem_name: "already-exists", trusted_publisher_type: "OIDC::TrustedPublisher::GitHubAction",
                       trusted_publisher: { repository_owner: "example", repository_name: "already-exists", workflow_filename: "push_gem.yml" } },
             headers: { "HTTP_AUTHORIZATION" => "12345" }

        assert_response :unprocessable_content
        assert_includes response.parsed_body["errors"].keys, "rubygem_name"
      end
    end

    context "on POST to create with an unsupported type" do
      should "return 422" do
        post api_v1_oidc_pending_trusted_publishers_path,
             params: { rubygem_name: "x", trusted_publisher_type: "Hash", trusted_publisher: { repository_owner: "example" } },
             headers: { "HTTP_AUTHORIZATION" => "12345" }

        assert_response :unprocessable_content
        assert_equal "Unsupported trusted publisher type", response.parsed_body["error"]
      end
    end

    context "on POST to create with invalid config" do
      should "return 422 with errors" do
        stub_request(:get, "https://api.github.com/users/example")
          .to_return(status: 200, body: { id: "123456" }.to_json, headers: { "Content-Type" => "application/json" })
        post api_v1_oidc_pending_trusted_publishers_path,
             params: { rubygem_name: "x", trusted_publisher_type: "OIDC::TrustedPublisher::GitHubAction",
                       trusted_publisher: { repository_owner: "example" } },
             headers: { "HTTP_AUTHORIZATION" => "12345" }

        assert_response :unprocessable_content
        assert_predicate response.parsed_body["errors"], :present?
      end
    end

    context "on GET to index" do
      should "return only the calling user's unexpired pending publishers" do
        mine = create(:oidc_pending_trusted_publisher, user: @api_key.user)
        create(:oidc_pending_trusted_publisher) # another user
        create(:oidc_pending_trusted_publisher, user: @api_key.user, expires_at: 1.hour.ago) # expired

        get api_v1_oidc_pending_trusted_publishers_path, headers: { "HTTP_AUTHORIZATION" => "12345" }

        assert_response :success
        assert_equal([mine.id], response.parsed_body.pluck("id"))

        # Contract the CLI depends on: each item carries a nested trusted_publisher object.
        response.parsed_body.each do |item|
          assert_kind_of Hash, item["trusted_publisher"]
          assert_predicate item["trusted_publisher"]["repository_owner"], :present?
        end
      end
    end
  end

  context "with a key lacking configure_trusted_publishers scope" do
    setup do
      @api_key = create(:api_key, key: "12345", scopes: %i[push_rubygem])
    end

    should "deny create" do
      post api_v1_oidc_pending_trusted_publishers_path,
           params: { rubygem_name: "x", trusted_publisher_type: "OIDC::TrustedPublisher::GitHubAction",
                     trusted_publisher: { repository_owner: "example", repository_name: "x", workflow_filename: "push_gem.yml" } },
           headers: { "HTTP_AUTHORIZATION" => "12345" }

      assert_response :forbidden
    end
  end

  context "with a gem-scoped configure_trusted_publishers key" do
    setup do
      @owner = create(:user)
      @rubygem = create(:rubygem, owners: [@owner])
      @api_key = create(:api_key, key: "12345", scopes: %i[configure_trusted_publishers],
                                  owner: @owner, rubygem: @rubygem)
    end

    should "deny create (gem-scoped keys cannot register pending publishers)" do
      post api_v1_oidc_pending_trusted_publishers_path,
           params: { rubygem_name: "x", trusted_publisher_type: "OIDC::TrustedPublisher::GitHubAction",
                     trusted_publisher: { repository_owner: "example", repository_name: "x", workflow_filename: "push_gem.yml" } },
           headers: { "HTTP_AUTHORIZATION" => "12345" }

      assert_response :forbidden
      assert_includes @response.body, "This API key cannot perform the specified action on this gem."
    end
  end

  context "with a trusted-publisher-owned (non-user) key" do
    setup do
      @api_key = create(:api_key, :trusted_publisher, key: "12345", scopes: %i[configure_trusted_publishers])
    end

    should "deny create" do
      post api_v1_oidc_pending_trusted_publishers_path,
           params: { rubygem_name: "x", trusted_publisher_type: "OIDC::TrustedPublisher::GitHubAction",
                     trusted_publisher: { repository_owner: "example", repository_name: "x", workflow_filename: "push_gem.yml" } },
           headers: { "HTTP_AUTHORIZATION" => "12345" }

      assert_response :forbidden
    end
  end

  context "with MFA (ui_and_api) required on the key's user" do
    setup do
      @user = create(:user, :mfa_enabled, totp_seed: ROTP::Base32.random_base32)
      @api_key = create(:api_key, key: "12345", scopes: %i[configure_trusted_publishers], owner: @user)
    end

    should "reject create without OTP" do
      post api_v1_oidc_pending_trusted_publishers_path,
           params: { rubygem_name: "x", trusted_publisher_type: "OIDC::TrustedPublisher::GitHubAction",
                     trusted_publisher: { repository_owner: "example", repository_name: "x", workflow_filename: "push_gem.yml" } },
           headers: { "HTTP_AUTHORIZATION" => "12345" }

      assert_response :unauthorized
    end
  end
end
