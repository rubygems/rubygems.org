require "test_helper"

class OIDC::ApiKeyRolesControllerIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    @id_token = create(:oidc_id_token, user: @user)
    @api_key_role = @id_token.api_key_role
  end

  context "with a verified session" do
    setup do
      post(authenticate_session_path(verify_password: { password: PasswordHelpers::SECURE_TEST_PASSWORD }))
    end

    should "get show" do
      get profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :success
    end

    should "get show format json" do
      get profile_oidc_api_key_role_url(@api_key_role.token, format: :json)

      assert_response :success
    end

    should "get index" do
      get profile_oidc_api_key_roles_url

      assert_response :success
    end

    should "get new" do
      get new_profile_oidc_api_key_role_url

      assert_response :success
    end

    should "get new scoped to a rubygem" do
      rubygem = create(:rubygem, owners: [@user])
      create(:version, rubygem: rubygem)
      get new_profile_oidc_api_key_role_url(rubygem: rubygem.name)

      assert_response :success
      page.assert_selector :field, "oidc_api_key_role[name]", with: "Push #{rubygem.name}"
      page.assert_selector :select, "Gem Scope", selected: [rubygem.name]
    end

    should "get new scoped to a rubygem with a taken name" do
      rubygem = create(:rubygem, owners: [@user])
      create(:version, rubygem: rubygem)
      create(:oidc_api_key_role, name: "Push #{rubygem.name}", user: @user)
      get new_profile_oidc_api_key_role_url(rubygem: rubygem.name)

      assert_response :success
      page.assert_selector :field, "oidc_api_key_role[name]", with: "Push #{rubygem.name} 2"
      page.assert_selector :select, "Gem Scope", selected: [rubygem.name]
    end

    should "get github_actions_workflow" do
      get github_actions_workflow_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :success
    end

    should "get github_actions_workflow with a github actions role" do
      provider = create(:oidc_provider, issuer: "https://token.actions.githubusercontent.com")
      @api_key_role = create(:oidc_api_key_role, provider:, user: @user).token
      get github_actions_workflow_profile_oidc_api_key_role_url(@api_key_role)

      assert_response :success
    end

    should "get github_actions_workflow with a github actions role scoped to a gem" do
      provider = create(:oidc_provider, issuer: "https://token.actions.githubusercontent.com")
      rubygem = create(:rubygem, owners: [@user])
      create(:version, rubygem: rubygem, metadata: { "source_code_uri" => "https://github.com/example/#{rubygem.name}" })

      @api_key_role = create(:oidc_api_key_role,
        user: @user,
        provider:,
        api_key_permissions: { scopes: ["push_rubygem"], gems: [rubygem.name] })
      get github_actions_workflow_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :success
    end

    should "get github_actions_workflow with a configured aud" do
      provider = create(:oidc_provider, issuer: "https://token.actions.githubusercontent.com")

      @api_key_role = create(:oidc_api_key_role,
        user: @user,
        provider:,
        access_policy: { statements: [{ effect: "allow", conditions: [{ claim: "aud", operator: "string_equals", value: "example.com" }] }] })
      get github_actions_workflow_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :success
      page.assert_text "audience: example.com"
    end

    should "get github_actions_workflow with a configured default aud" do
      provider = create(:oidc_provider, issuer: "https://token.actions.githubusercontent.com")

      @api_key_role = create(:oidc_api_key_role,
        user: @user,
        provider:,
        access_policy: { statements: [{ effect: "allow", conditions: [{ claim: "aud", operator: "string_equals", value: "rubygems.org" }] }] })
      get github_actions_workflow_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :success
      page.assert_no_text "audience:"
    end

    should "delete" do
      delete profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :redirect
      assert_redirected_to profile_oidc_api_key_roles_path

      follow_redirect!

      page.assert_no_text @api_key_role.token

      get profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :success
      page.assert_selector "h2", text: /This role was deleted .+ ago and can no longer be used/

      delete profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :redirect
      assert_redirected_to profile_oidc_api_key_roles_path

      follow_redirect!

      page.assert_selector ".flash #flash_error", text: "The role has been deleted."

      get edit_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :redirect
      assert_redirected_to profile_oidc_api_key_roles_path

      follow_redirect!

      page.assert_selector ".flash #flash_error", text: "The role has been deleted."
    end
  end

  context "without a verified session" do
    should "redirect show to verify" do
      get profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect index to verify" do
      get profile_oidc_api_key_roles_url

      assert_response :redirect
      assert_redirected_to verify_session_path
    end

    should "redirect github_actions_workflow to verify" do
      get github_actions_workflow_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :redirect
      assert_redirected_to verify_session_path
    end
  end
end
