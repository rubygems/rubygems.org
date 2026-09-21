# frozen_string_literal: true

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

    should "get index with both table links underlined" do
      get profile_oidc_api_key_roles_url

      assert_response :success

      # The name used to render in body text with only a hover underline, so there
      # was nothing to show it was clickable. Both links in the row now share one style.
      name_link = page.find_link(@api_key_role.name, href: profile_oidc_api_key_role_path(@api_key_role.token))
      provider_link = page.find_link(@api_key_role.provider.issuer,
        href: profile_oidc_provider_path(@api_key_role.provider))

      assert_includes name_link[:class].split, "underline"
      assert_includes provider_link[:class].split, "underline"
      assert_equal name_link[:class], provider_link[:class]
    end

    should "get index with per-role edit and delete actions" do
      get profile_oidc_api_key_roles_url

      assert_response :success
      page.assert_selector "form[action='#{edit_profile_oidc_api_key_role_path(@api_key_role.token)}'][method='get'] button",
        text: "Edit"
      page.assert_selector "form[action='#{profile_oidc_api_key_role_path(@api_key_role.token)}'][method='post'] " \
                           "input[name='_method'][value='delete']", visible: :all
      page.assert_selector "form[action='#{profile_oidc_api_key_role_path(@api_key_role.token)}'] " \
                           "button[data-confirm='Are you sure you want to delete the role \"#{@api_key_role.name}\"?']",
        text: "Delete"
    end

    should "not offer edit or delete actions for a deleted role" do
      @api_key_role.update!(deleted_at: Time.current)

      get profile_oidc_api_key_roles_url

      assert_response :success
      page.assert_no_text @api_key_role.token
      page.assert_no_selector "form[action='#{edit_profile_oidc_api_key_role_path(@api_key_role.token)}']"
      page.assert_no_selector "form[action='#{profile_oidc_api_key_role_path(@api_key_role.token)}']"
    end

    should "get new" do
      get new_profile_oidc_api_key_role_url

      assert_response :success
    end

    should "omit the empty repository placeholder when creating a read-only role" do
      pkey = OpenSSL::PKey::RSA.generate(2048)
      providers = [
        create(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER, pkey:),
        create(:oidc_provider_buildkite, pkey:)
      ]
      get new_profile_oidc_api_key_role_url

      assert_response :success

      providers.each_with_index do |provider, index|
        name = "Read-only #{index}"
        post profile_oidc_api_key_roles_url, params: { oidc_api_key_role: {
          name:, oidc_provider_id: provider.id,
          api_key_permissions: { scopes: ["index_rubygems"], valid_for: "PT30M", gems: [""] },
          access_policy: { statements_attributes: { "0" => {
            effect: "allow", conditions_attributes: {
              "0" => { claim: "aud", operator: "string_equals", value: Gemcutter::HOST },
              "1" => { claim: "repository", operator: "string_equals", value: "" }
            }
          } } }
        } }

        assert_response :redirect
        role = @user.oidc_api_key_roles.find_by!(name:)

        assert_equal ["aud"], role.access_policy.statements.first.conditions.map(&:claim)

        jwt = JSON::JWT.new(
          "iss" => provider.issuer, "aud" => Gemcutter::HOST,
          "sub" => "repo:unrelated/repo:ref:refs/heads/main",
          "jti" => SecureRandom.uuid, "iat" => Time.current.to_i,
          "nbf" => 1.minute.ago.to_i, "exp" => 5.minutes.from_now.to_i
        ).sign(pkey.to_jwk).to_s
        post assume_role_api_v1_oidc_api_key_role_path(role.token), params: { jwt: }

        assert_response :created
        assert_equal ["index_rubygems"], response.parsed_body["scopes"]
      end
    end

    should "reject a sensitive role when the repository placeholder is left blank" do
      provider = create(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER)
      %w[push_rubygem access_webhooks access_oidc_api_key_roles show_dashboard].each do |scope|
        assert_no_difference ["OIDC::ApiKeyRole.count", "ApiKey.count", "OIDC::IdToken.count"] do
          assert_no_enqueued_emails do
            post profile_oidc_api_key_roles_url, params: { oidc_api_key_role: {
              name: "Unbound #{scope}", oidc_provider_id: provider.id,
              api_key_permissions: { scopes: [scope], valid_for: "PT30M", gems: [""] },
              access_policy: { statements_attributes: { "0" => {
                effect: "allow", conditions_attributes: {
                  "0" => { claim: "aud", operator: "string_equals", value: Gemcutter::HOST },
                  "1" => { claim: "repository", operator: "string_equals", value: "" }
                }
              } } }
            } }
          end
        end

        assert_response :success
        assert_includes response.body, "must bind the token to a repository"
      end
    end

    should "keep a blank repository condition on a deny statement rather than widening the denial" do
      policy = { statements_attributes: {
        "0" => { effect: "allow", conditions_attributes: {
          "0" => { claim: "sub", operator: "string_equals", value: "repo:segiddins/oidc-test:ref:refs/heads/main" }
        } },
        "1" => { effect: "deny", conditions_attributes: {
          "0" => { claim: "aud", operator: "string_equals", value: Gemcutter::HOST },
          "1" => { claim: "repository", operator: "string_equals", value: "" }
        } }
      } }

      patch profile_oidc_api_key_role_url(@api_key_role.token), params: { oidc_api_key_role: { access_policy: policy } }

      assert_response :redirect
      saved_policy = @api_key_role.reload.access_policy

      assert_equal %w[aud repository], saved_policy.statements.last.conditions.map(&:claim)
      assert_nil saved_policy.verify_access!(JSON::JWT.new(
                                               "iss" => @api_key_role.provider.issuer,
                                               "sub" => "repo:segiddins/oidc-test:ref:refs/heads/main",
                                               "aud" => Gemcutter::HOST,
                                               "repository" => "segiddins/oidc-test"
                                             ))
    end

    should "not activate an unmatchable legacy role when editing its name" do
      pkey = OpenSSL::PKey::RSA.generate(2048)
      provider = create(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER, pkey:)
      role = create(:oidc_api_key_role, user: @user, provider:)
      sub = "repo:segiddins/oidc-test:ref:refs/heads/main"
      role.update_column(:access_policy, { statements: [
                           effect: "allow", principal: { oidc: provider.issuer }, conditions: [
                             { claim: "sub", operator: "string_equals", value: sub },
                             { claim: "repository", operator: "string_equals", value: "" }
                           ]
                         ] })
      jwt = JSON::JWT.new(
        "iss" => provider.issuer, "aud" => Gemcutter::HOST,
        "sub" => sub, "repository" => "segiddins/oidc-test",
        "jti" => SecureRandom.uuid, "iat" => Time.current.to_i,
        "nbf" => 1.minute.ago.to_i, "exp" => 5.minutes.from_now.to_i
      ).sign(pkey.to_jwk).to_s

      2.times do |attempt|
        if attempt == 1
          patch profile_oidc_api_key_role_url(role.token), params: { oidc_api_key_role: {
            name: "Renamed role", access_policy: { statements_attributes: { "0" => {
              effect: "allow", conditions_attributes: {
                "0" => { claim: "sub", operator: "string_equals", value: sub },
                "1" => { claim: "repository", operator: "string_equals", value: "" }
              }
            } } }
          } }

          assert_response :redirect
        end

        assert_no_difference ["ApiKey.count", "OIDC::IdToken.count"] do
          assert_no_enqueued_emails do
            post assume_role_api_v1_oidc_api_key_role_path(role.token), params: { jwt: }
          end
        end

        assert_response :not_found
      end

      assert_equal "Renamed role", role.reload.name
      assert_equal %w[sub repository], role.access_policy.statements.first.conditions.map(&:claim)
    end

    should "not raise on array-shaped nested statements or conditions" do
      [
        { statements_attributes: [effect: "allow", conditions_attributes: {
          "0" => { claim: "aud", operator: "string_equals", value: Gemcutter::HOST }
        }] },
        { statements_attributes: { "0" => { effect: "allow", conditions_attributes: [
          claim: "aud", operator: "string_equals", value: Gemcutter::HOST
        ] } } }
      ].each do |policy|
        patch profile_oidc_api_key_role_url(@api_key_role.token),
          params: { oidc_api_key_role: { access_policy: policy } }.to_json,
          headers: { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "text/html" }

        assert_response :success
        assert_equal "sub", @api_key_role.reload.access_policy.statements.first.conditions.first.claim
      end
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

      # This gem link was the only OIDC link styled without an underline or a
      # dark-theme colour. Split on whitespace so "hover:underline" cannot match.
      gem_link = page.find_link(href: rubygem_path(rubygem.name))

      assert_includes gem_link[:class].split, "underline"
      assert_includes gem_link[:class].split, "dark:text-orange-400"
    end

    should "get github_actions_workflow with a configured aud" do
      provider = create(:oidc_provider, issuer: "https://token.actions.githubusercontent.com")

      @api_key_role = create(:oidc_api_key_role,
        user: @user,
        provider:,
        access_policy: { statements: [effect: "allow", conditions: [
          { claim: "aud", operator: "string_equals", value: "example.com" },
          { claim: "repository", operator: "string_equals", value: "example/repo" }
        ]] })
      get github_actions_workflow_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :success
      page.assert_text "audience: example.com"
    end

    should "get github_actions_workflow with a configured default aud" do
      provider = create(:oidc_provider, issuer: "https://token.actions.githubusercontent.com")

      @api_key_role = create(:oidc_api_key_role,
        user: @user,
        provider:,
        access_policy: { statements: [effect: "allow", conditions: [
          { claim: "aud", operator: "string_equals", value: "rubygems.org" },
          { claim: "repository", operator: "string_equals", value: "example/repo" }
        ]] })
      get github_actions_workflow_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :success
      page.assert_no_text "audience:"
    end

    should "update an access policy at the complexity limits from JSON" do
      patch profile_oidc_api_key_role_url(@api_key_role.token),
        params: access_policy_params(10).to_json,
        headers: { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "text/html" }

      assert_response :redirect
      assert_equal(10, @api_key_role.reload.access_policy.statements.sum { it.conditions.size })
    end

    should "reject an access policy over the complexity limits from JSON" do
      original_policy = @api_key_role.access_policy.as_json
      api_key_count = ApiKey.count
      id_token_count = OIDC::IdToken.count

      assert_no_enqueued_emails do
        patch profile_oidc_api_key_role_url(@api_key_role.token),
          params: access_policy_params(11).to_json,
          headers: { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "text/html" }
      end

      assert_response :success
      assert_includes response.body, "must contain at most 5 statements and 10 conditions in total"
      assert_equal original_policy, @api_key_role.reload.access_policy.as_json
      assert_equal api_key_count, ApiKey.count
      assert_equal id_token_count, OIDC::IdToken.count
    end

    should "reject a pattern that escapes the whole-claim anchors without side effects" do
      attributes = @api_key_role.attributes
      params = access_policy_params(1)
      params[:oidc_api_key_role][:access_policy][:statements_attributes]["0"][:conditions_attributes]["0"] = {
        operator: "string_matches", claim: "sub", value: "foo)|(?:bar"
      }

      assert_no_difference ["ApiKey.count", "OIDC::IdToken.count", "Events::UserEvent.count", "Audit.count"] do
        assert_no_enqueued_emails do
          patch profile_oidc_api_key_role_url(@api_key_role.token),
            params: params.to_json,
            headers: { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "text/html" }
        end
      end

      assert_response :success
      page.assert_text "is not a valid regular expression"

      assert_equal attributes, @api_key_role.reload.attributes
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

      page.assert_selector "#flash_error", text: "The role has been deleted."

      get edit_profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :redirect
      assert_redirected_to profile_oidc_api_key_roles_path

      follow_redirect!

      page.assert_selector "#flash_error", text: "The role has been deleted."
    end

    should "delete a role with a legacy access policy over the complexity limits" do
      @api_key_role.update_column(:access_policy, persisted_access_policy(11))

      delete profile_oidc_api_key_role_url(@api_key_role.token)

      assert_response :redirect
      assert_redirected_to profile_oidc_api_key_roles_path
      assert_predicate @api_key_role.reload, :deleted_at?
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

  private

  def access_policy_params(condition_count)
    conditions = condition_count.times.to_h do |index|
      [index.to_s, operator: "string_equals", claim: "sub", value: "repo:example/repo:ref:refs/heads/main"]
    end

    {
      oidc_api_key_role: {
        access_policy: {
          statements_attributes: {
            "0" => { effect: "allow", conditions_attributes: conditions }
          }
        }
      }
    }
  end

  def persisted_access_policy(condition_count)
    {
      statements: [

        effect: "allow",
        principal: { oidc: @api_key_role.provider.issuer },
        conditions: Array.new(condition_count) do
          { operator: "string_equals", claim: "sub", value: "value" }
        end

      ]
    }
  end
end
