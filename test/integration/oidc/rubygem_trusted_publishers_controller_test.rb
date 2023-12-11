require "test_helper"

class OIDC::RubygemTrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    @rubygem = create(:rubygem, owners: [@user])
    create(:version, rubygem: @rubygem)
    @trusted_publisher = create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)
  end

  context "with a verified session" do
    setup do
      post(authenticate_session_path(verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD }))
    end

    should "respond forbidden for non-owner" do
      @rubygem.disown

      get rubygem_trusted_publishers_url(@rubygem.slug)

      assert_response :forbidden
    end

    should "get index" do
      create(:oidc_rubygem_trusted_publisher, rubygem: @rubygem,
             trusted_publisher: create(:oidc_trusted_publisher_github_action, environment: "production"))
      get rubygem_trusted_publishers_url(@rubygem.slug)

      assert_response :success
    end

    should "get new" do
      get new_rubygem_trusted_publisher_url(@rubygem.slug)

      assert_response :success
    end

    should "get new for a github rubygem" do
      stub_request(:get, "https://api.github.com/repos/example/rubygem1/contents/.github/workflows")
        .to_return(status: 200, body: [
          { name: "ci.yml", type: "file" },
          { name: "push_rubygem.yml", type: "file" },
          { name: "push_README.md", type: "file" },
          { name: "push.yml", type: "directory" }
        ].to_json, headers: { "Content-Type" => "application/json" })

      create(:version, rubygem: @rubygem, metadata: { "source_code_uri" => "https://github.com/example/rubygem1" })

      get new_rubygem_trusted_publisher_url(@rubygem.slug)

      assert_response :success

      page.assert_selector("input[name='oidc_rubygem_trusted_publisher[trusted_publisher_attributes][repository_owner]'][value='example']")
      page.assert_selector("input[name='oidc_rubygem_trusted_publisher[trusted_publisher_attributes][repository_name]'][value='rubygem1']")
      page.assert_selector("input[name='oidc_rubygem_trusted_publisher[trusted_publisher_attributes][workflow_filename]'][value='push_rubygem.yml']")
    end

    should "get new for a github rubygem with no found workflows" do
      stub_request(:get, "https://api.github.com/repos/example/rubygem1/contents/.github/workflows")
        .to_return(status: 404, body: { message: "Not Found" }.to_json, headers: { "Content-Type" => "application/json" })

      create(:version, rubygem: @rubygem, metadata: { "source_code_uri" => "https://github.com/example/rubygem1" })

      get new_rubygem_trusted_publisher_url(@rubygem.slug)

      assert_response :success

      page.assert_selector("input[name='oidc_rubygem_trusted_publisher[trusted_publisher_attributes][repository_owner]'][value='example']")
      page.assert_selector("input[name='oidc_rubygem_trusted_publisher[trusted_publisher_attributes][repository_name]'][value='rubygem1']")
    end

    should "create trusted publisher" do
      stub_request(:get, "https://api.github.com/users/example")
        .to_return(status: 200, body: { id: "54321" }.to_json, headers: { "Content-Type" => "application/json" })

      assert_difference("OIDC::RubygemTrustedPublisher.count") do
        trusted_publisher = build(:oidc_rubygem_trusted_publisher, rubygem: @rubygem)
        post rubygem_trusted_publishers_url(@rubygem.slug), params: {
          oidc_rubygem_trusted_publisher: {
            trusted_publisher_type: trusted_publisher.trusted_publisher_type,
            trusted_publisher_attributes: trusted_publisher.trusted_publisher.as_json
          }
        }
      end

      assert_redirected_to rubygem_trusted_publishers_url(@rubygem.slug)
    end

    should "error creating trusted publisher with type" do
      assert_no_difference("OIDC::RubygemTrustedPublisher.count") do
        post rubygem_trusted_publishers_url(@rubygem.slug), params: {
          oidc_rubygem_trusted_publisher: {
            trusted_publisher_type: "Hash",
            trusted_publisher_attributes: { repository_owner: "example" }
          }
        }

        assert_response :redirect
        assert_equal "Unsupported trusted publisher type", flash[:error]
      end
    end

    should "error creating trusted publisher with unknown repository owner" do
      stub_request(:get, "https://api.github.com/users/example")
        .to_return(status: 404, body: { message: "Not Found" }.to_json, headers: { "Content-Type" => "application/json" })

      assert_no_difference("OIDC::RubygemTrustedPublisher.count") do
        post rubygem_trusted_publishers_url(@rubygem.slug), params: {
          oidc_rubygem_trusted_publisher: {
            trusted_publisher_type: OIDC::TrustedPublisher::GitHubAction.polymorphic_name,
            trusted_publisher_attributes: { repository_owner: "example" }
          }
        }

        assert_response :unprocessable_entity
        assert_equal [
          "Trusted publisher repository name can't be blank",
          "Trusted publisher workflow filename can't be blank",
          "Trusted publisher repository owner can't be blank"
        ].to_sentence, flash[:error]
      end
    end

    should "error creating invalid trusted publisher" do
      stub_request(:get, "https://api.github.com/users/example")
        .to_return(status: 200, body: { id: "54321" }.to_json, headers: { "Content-Type" => "application/json" })

      assert_no_difference("OIDC::RubygemTrustedPublisher.count") do
        post rubygem_trusted_publishers_url(@rubygem.slug), params: {
          oidc_rubygem_trusted_publisher: {
            trusted_publisher_type: OIDC::TrustedPublisher::GitHubAction.polymorphic_name,
            trusted_publisher_attributes: { repository_name: "rubygem1", repository_owner: "example", workflow_filename: "ci.NO" }
          }
        }

        assert_response :unprocessable_entity
        assert_equal ["Trusted publisher workflow filename must end with .yml or .yaml"].to_sentence, flash[:error]
      end
    end

    should "destroy trusted publisher" do
      assert_difference("OIDC::RubygemTrustedPublisher.count", -1) do
        delete rubygem_trusted_publisher_url(@rubygem.slug, @trusted_publisher)
      end

      assert_redirected_to rubygem_trusted_publishers_url(@rubygem.slug)

      assert_raises ActiveRecord::RecordNotFound do
        @trusted_publisher.reload
      end
    end
  end

  context "without a verified session" do
    should "redirect index to verify" do
      get rubygem_trusted_publishers_url(@rubygem.slug)

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect new to verify" do
      get new_rubygem_trusted_publisher_url(@rubygem.slug)

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect create to verify" do
      post rubygem_trusted_publishers_url(@rubygem.slug)

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect destroy to verify" do
      delete new_rubygem_trusted_publisher_url(@rubygem.slug)

      assert_response :redirect
      assert_redirected_to verify_session_path
    end
  end
end
