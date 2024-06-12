require "test_helper"

class OIDC::PendingTrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    @trusted_publisher = create(:oidc_pending_trusted_publisher, user: @user)
  end

  context "with a verified session" do
    setup do
      post(authenticate_session_path(verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD }))
    end

    should "get index" do
      get profile_oidc_pending_trusted_publishers_url

      assert_response :success
    end

    should "get new" do
      get new_profile_oidc_pending_trusted_publisher_url

      assert_response :success
    end

    should "create trusted publisher" do
      stub_request(:get, "https://api.github.com/users/example")
        .to_return(status: 200, body: { id: "54321" }.to_json, headers: { "Content-Type" => "application/json" })

      assert_difference("OIDC::PendingTrustedPublisher.count") do
        trusted_publisher = build(:oidc_pending_trusted_publisher)
        post profile_oidc_pending_trusted_publishers_url, params: {
          oidc_pending_trusted_publisher: {
            rubygem_name: trusted_publisher.rubygem_name,
            trusted_publisher_type: trusted_publisher.trusted_publisher_type,
            trusted_publisher_attributes: trusted_publisher.trusted_publisher.as_json
          }
        }
      end

      assert_redirected_to profile_oidc_pending_trusted_publishers_url
    end

    should "error creating trusted publisher with type" do
      assert_no_difference("OIDC::PendingTrustedPublisher.count") do
        post profile_oidc_pending_trusted_publishers_url, params: {
          oidc_pending_trusted_publisher: {
            rubygem_name: "rubygem1",
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

      assert_no_difference("OIDC::PendingTrustedPublisher.count") do
        post profile_oidc_pending_trusted_publishers_url, params: {
          oidc_pending_trusted_publisher: {
            rubygem_name: "rubygem1",
            trusted_publisher_type: OIDC::TrustedPublisher::GitHubAction.polymorphic_name,
            trusted_publisher_attributes: { repository_owner: "example" }
          }
        }

        assert_response :unprocessable_content
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

      assert_no_difference("OIDC::PendingTrustedPublisher.count") do
        post profile_oidc_pending_trusted_publishers_url, params: {
          oidc_pending_trusted_publisher: {
            rubygem_name: "rubygem1",
            trusted_publisher_type: OIDC::TrustedPublisher::GitHubAction.polymorphic_name,
            trusted_publisher_attributes: { repository_name: "rubygem1", repository_owner: "example", workflow_filename: "ci.NO" }
          }
        }

        assert_response :unprocessable_content
        assert_equal ["Trusted publisher workflow filename must end with .yml or .yaml"].to_sentence, flash[:error]
      end
    end

    should "destroy trusted publisher" do
      assert_difference("OIDC::PendingTrustedPublisher.count", -1) do
        delete profile_oidc_pending_trusted_publisher_url(@trusted_publisher)
      end

      assert_redirected_to profile_oidc_pending_trusted_publishers_url

      assert_raises ActiveRecord::RecordNotFound do
        @trusted_publisher.reload
      end
    end

    should "return not found on destroy for other users trusted publisher" do
      trusted_publisher = create(:oidc_pending_trusted_publisher)
      assert_no_difference("OIDC::PendingTrustedPublisher.count") do
        delete profile_oidc_pending_trusted_publisher_url(trusted_publisher)

        assert_response :not_found
      end
    end
  end

  context "without a verified session" do
    should "redirect index to verify" do
      get profile_oidc_pending_trusted_publishers_url

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect new to verify" do
      get new_profile_oidc_pending_trusted_publisher_url

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect create to verify" do
      post profile_oidc_pending_trusted_publishers_url

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect destroy to verify" do
      delete new_profile_oidc_pending_trusted_publisher_url

      assert_response :redirect
      assert_redirected_to verify_session_path
    end
  end
end
