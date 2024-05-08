require "test_helper"

class Api::V1::OIDC::RubygemTrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  make_my_diffs_pretty!

  setup do
    create(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER)
  end

  context "without an API key" do
    context "on GET to index" do
      setup do
        get api_v1_rubygem_trusted_publishers_path("rails")
      end

      should "deny access" do
        assert_response :unauthorized
      end
    end

    context "on GET to show" do
      setup do
        get api_v1_rubygem_trusted_publisher_path("rails", 0)
      end

      should "deny access" do
        assert_response :unauthorized
      end
    end

    context "on POST to create" do
      setup do
        post api_v1_rubygem_trusted_publishers_path("rails"),
             params: {}
      end

      should "deny access" do
        assert_response :unauthorized
      end
    end

    context "on DELETE to destory" do
      setup do
        delete api_v1_rubygem_trusted_publisher_path("rails", 0),
               params: {}
      end

      should "deny access" do
        assert_response :unauthorized
      end
    end
  end

  context "on GET to show without configure_trusted_publishers scope" do
    setup do
      @api_key = create(:api_key, key: "12345", scopes: %i[push_rubygem])
      @rubygem = create(:rubygem, owners: [@api_key.owner])

      get api_v1_rubygem_trusted_publisher_path(@rubygem.slug, 2),
          headers: { "HTTP_AUTHORIZATION" => "12345" }
    end

    should "deny access" do
      assert_response :forbidden
      assert_match "The API key doesn't have access", @response.body
    end
  end

  context "with an authorized API key" do
    setup do
      @api_key = create(:api_key, key: "12345", scopes: %i[configure_trusted_publishers])
      @rubygem = create(:rubygem, owners: [@api_key.owner], indexed: true)
    end

    context "on GET to index" do
      setup do
        get api_v1_rubygem_trusted_publishers_path(@rubygem.slug),
            headers: { "HTTP_AUTHORIZATION" => "12345" }
      end

      should "return all trusted publishers" do
        assert_response :success
      end

      context "with a trusted publisher" do
        setup do
          create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)
          get api_v1_rubygem_trusted_publishers_path(@rubygem.slug),
              headers: { "HTTP_AUTHORIZATION" => "12345" }
        end

        should "return the trusted publisher" do
          assert_response :success
          assert_equal 1, @response.parsed_body.size
        end
      end
    end

    context "on GET to show" do
      setup do
        @trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)
        get api_v1_rubygem_trusted_publisher_path(@rubygem.slug, @trusted_publisher.id),
            headers: { "HTTP_AUTHORIZATION" => "12345" }
      end

      should "return the trusted publisher" do
        repository_name = @trusted_publisher.trusted_publisher.repository_name

        assert_response :success
        assert_equal(
          { "id" => @trusted_publisher.id,
            "trusted_publisher_type" => "OIDC::TrustedPublisher::GitHubAction",
            "trusted_publisher" => {
              "name" => "GitHub Actions example/#{repository_name} @ .github/workflows/push_gem.yml",
              "repository_owner" => "example",
              "repository_name" => repository_name,
              "repository_owner_id" => "123456",
              "workflow_filename" => "push_gem.yml",
              "environment" => nil
            } }, @response.parsed_body
        )
      end
    end

    context "on POST to create" do
      should "create a trusted publisher" do
        stub_request(:get, "https://api.github.com/users/example")
          .to_return(status: 200, body: { id: "123456" }.to_json, headers: { "Content-Type" => "application/json" })

        post api_v1_rubygem_trusted_publishers_path(@rubygem.slug),
             params: {
               trusted_publisher_type: "OIDC::TrustedPublisher::GitHubAction",
               trusted_publisher: {
                 repository_owner: "example",
                 repository_name: "rubygem1",
                 workflow_filename: "push_gem.yml"
               }
             },
             headers: { "HTTP_AUTHORIZATION" => "12345" }

        assert_response :created
        trusted_publisher = OIDC::RubygemTrustedPublisher.find(response.parsed_body["id"])

        assert_equal @rubygem, trusted_publisher.rubygem
        assert_equal(
          { "id" => response.parsed_body["id"],
            "trusted_publisher_type" => "OIDC::TrustedPublisher::GitHubAction",
            "trusted_publisher" => {
              "name" => "GitHub Actions example/rubygem1 @ .github/workflows/push_gem.yml",
              "repository_owner" => "example",
              "repository_name" => "rubygem1",
              "repository_owner_id" => "123456",
              "workflow_filename" => "push_gem.yml",
              "environment" => nil
            } }, response.parsed_body
        )
      end

      should "error creating trusted publisher with unknown type" do
        post api_v1_rubygem_trusted_publishers_path(@rubygem.slug),
             params: {
               trusted_publisher_type: "Hash",
               trusted_publisher: { repository_owner: "example" }
             },
             headers: { "HTTP_AUTHORIZATION" => "12345" }

        assert_response :unprocessable_entity
        assert_equal "Unsupported trusted publisher type", response.parsed_body["error"]
      end
    end

    context "on DELETE to destroy" do
      should "destroy the trusted publisher" do
        trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)

        delete api_v1_rubygem_trusted_publisher_path(@rubygem.slug, trusted_publisher.id),
               headers: { "HTTP_AUTHORIZATION" => "12345" }

        assert_response :no_content
        assert OIDC::RubygemTrustedPublisher.none?(id: trusted_publisher.id)
      end
    end
  end
end
