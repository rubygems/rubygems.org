require "application_system_test_case"

class OIDCTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, password: PasswordHelpers::SECURE_TEST_PASSWORD)
    @provider = create(:oidc_provider, issuer: "https://token.actions.githubusercontent.com")
    @api_key_role = create(:oidc_api_key_role, user: @user, provider: @provider)
    @id_token = create(:oidc_id_token, user: @user, api_key_role: @api_key_role)
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  def verify_session # rubocop:disable Minitest/TestMethodName
    assert_title(/^Confirm Password/)
    fill_in "Password", with: @user.password
    click_button "Confirm"
  end

  test "viewing providers" do
    sign_in
    visit profile_oidc_providers_path
    verify_session

    assert_selector "h1", text: "OIDC Providers"
    assert_text(/displaying 1 provider/i)
    click_link "https://token.actions.githubusercontent.com"

    assert_selector "h1", text: "OIDC Provider"
    assert_text "https://token.actions.githubusercontent.com"
    assert_text "https://token.actions.githubusercontent.com/.well-known/jwks"
    assert_text(/Displaying 1 api key role/i)
    assert_link @id_token.api_key_role.name, href: profile_oidc_api_key_role_path(@id_token.api_key_role.token)
  end

  test "viewing api key roles" do
    sign_in
    visit profile_oidc_api_key_roles_path
    verify_session

    assert_selector "h1", text: "OIDC API Key Roles"
    assert_text(/displaying 1 api key role/i)
    click_link @id_token.api_key_role.name

    assert_selector "h1", text: "API Key Role #{@id_token.api_key_role.name}"
    assert_text @id_token.api_key_role.token
    assert_text "Scopes\npush_rubygem"
    assert_text "Gems\nAll Gems"
    assert_text "Valid for\n30 minutes"
    assert_text "Effect\nallow"
    assert_text "Principal\nhttps://token.actions.githubusercontent.com"
    assert_text "Conditions\nsub string_equals repo:segiddins/oidc-test:ref:refs/heads/main"
    assert_text(/Displaying 1 id token/i)
    assert_link "View provider https://token.actions.githubusercontent.com", href: profile_oidc_provider_path(@provider)
    assert_link @id_token.jti, href: profile_oidc_id_token_path(@id_token)
  end

  test "viewing id tokens" do
    sign_in
    visit profile_oidc_id_tokens_path
    verify_session

    assert_selector "h1", text: "OIDC ID Tokens"
    assert_text(/displaying 1 id token/i)
    click_link @id_token.jti

    assert_selector "h1", text: "OIDC ID Token"
    assert_text "CREATED AT\n#{@id_token.created_at.to_fs(:long)}"
    assert_text "EXPIRES AT\n#{@id_token.api_key.expires_at.to_fs(:long)}"
    assert_text "JWT ID\n#{@id_token.jti}"
    assert_link @api_key_role.name, href: profile_oidc_api_key_role_path(@api_key_role.token)
    assert_link "https://token.actions.githubusercontent.com", href: profile_oidc_provider_path(@provider)
    assert_text "jti\n#{@id_token.jti}"
    assert_text "claim1\nvalue1"
    assert_text "claim2\nvalue2"
    assert_text "typ\nJWT"
  end

  test "creating an api key role" do
    rubygem = create(:rubygem, owners: [@user])
    create(:version, rubygem: rubygem, metadata: { "source_code_uri" => "https://github.com/example/repo" })

    sign_in
    visit rubygem_path(rubygem.slug)
    click_link "OIDC: Create"
    verify_session

    assert_selector "h1", text: "New OIDC API Key Role"
    assert_field "Name", with: "Push #{rubygem.name}"
    assert_select "OIDC provider", options: ["https://token.actions.githubusercontent.com"], selected: "https://token.actions.githubusercontent.com"
    assert_checked_field "Push rubygem"
    assert_field "Valid for", with: "PT30M"
    assert_select "Gem Scope", options: ["All Gems", rubygem.name], selected: rubygem.name

    assert_select "Effect", options: %w[allow deny], selected: "allow",
      id: "oidc_api_key_role_access_policy_statements_attributes_0_effect"
    assert_field "Claim", with: "aud",
      id: "oidc_api_key_role_access_policy_statements_attributes_0_conditions_attributes_0_claim"
    assert_select "Operator", options: ["String Equals", "String Matches"], selected: "String Equals",
      id: "oidc_api_key_role_access_policy_statements_attributes_0_conditions_attributes_0_operator"
    assert_field "Value", with: Gemcutter::HOST,
      id: "oidc_api_key_role_access_policy_statements_attributes_0_conditions_attributes_0_value"
    assert_field "Claim", with: "repository",
      id: "oidc_api_key_role_access_policy_statements_attributes_0_conditions_attributes_1_claim"
    assert_select "Operator", options: ["String Equals", "String Matches"], selected: "String Equals",
      id: "oidc_api_key_role_access_policy_statements_attributes_0_conditions_attributes_1_operator"
    assert_field "Value", with: "example/repo",
      id: "oidc_api_key_role_access_policy_statements_attributes_0_conditions_attributes_1_value"

    scroll_to find(id: "oidc_api_key_role_access_policy_statements_attributes_0_conditions_attributes_1_claim")

    click_button "Create Api key role"

    assert_selector "h1", text: "API Key Role Push #{rubygem.name}"

    role = OIDC::ApiKeyRole.where(name: "Push #{rubygem.name}", user: @user, provider: @provider).sole

    token = role.token
    expected = {
      "name" => "Push #{rubygem.name}",
      "token" => token,
      "api_key_permissions" => {
        "scopes" => ["push_rubygem"],
        "valid_for" => 1800,
        "gems" => [rubygem.name]
      },
      "access_policy" => {
        "statements" => [
          {
            "effect" => "allow",
            "principal" => { "oidc" => "https://token.actions.githubusercontent.com" },
            "conditions" => [
              { "operator" => "string_equals", "claim" => "aud", "value" => "localhost" },
              { "operator" => "string_equals", "claim" => "repository", "value" => "example/repo" }
            ]
          }
        ]
      }
    }

    assert_equal(expected, role.as_json.slice(*expected.keys))

    click_button "Edit API Key Role"
    scroll_to :bottom
    click_button "Update Api key role"

    assert_selector "h1", text: "API Key Role Push #{rubygem.name}"
    assert_equal(expected, role.reload.as_json.slice(*expected.keys))

    click_button "Edit API Key Role"

    click_button "Add statement"

    statements = find_all(id: /oidc_api_key_role_access_policy_statements_attributes_\d+_wrapper/)

    assert_equal 2, statements.size

    new_statement = statements.last
    new_statement.select "deny", from: "Effect"
    new_statement.fill_in "Claim", with: "sub"
    new_statement.select "String Matches", from: "Operator"
    new_statement.fill_in "Value", with: "repo:example/repo:ref:refs/tags/.*"
    new_statement.click_button "Add condition"
    new_condition = new_statement.find_all(id: /oidc_api_key_role_access_policy_statements_attributes_\d+_conditions_attributes_\d+_wrapper/).last
    new_condition.fill_in "Claim", with: "fudge"
    new_condition.select "String Equals", from: "Operator"

    statements.first.find_all("button", text: "Remove condition").last.click

    assert_selector("button.form__remove_nested_button", text: "Remove condition", count: 3)

    click_button "Update Api key role"

    assert_text "Access policy statements[1] conditions[1] claim unknown for the provider"
    assert_equal(expected, role.reload.as_json.slice(*expected.keys))

    find_field("Claim", with: "fudge").fill_in with: "event_name"

    find_field("Name").fill_in with: "Push gems"
    select "All Gems", from: "Gem Scope"
    unselect rubygem.name, from: "Gem Scope"
    check "Yank rubygem"

    click_button "Update Api key role"

    assert_selector "h1", text: "API Key Role Push gems"
    assert_equal(expected.merge(
                   "name" => "Push gems",
                   "api_key_permissions" => {
                     "scopes" => %w[push_rubygem yank_rubygem], "valid_for" => 1800, "gems" => nil
                   },
                   "access_policy" => {
                     "statements" => [
                       {
                         "effect" => "allow",
                         "principal" => { "oidc" => "https://token.actions.githubusercontent.com" },
                         "conditions" => [
                           { "operator" => "string_equals", "claim" => "aud", "value" => "localhost" }
                         ]
                       },
                       {
                         "effect" => "allow",
                         "principal" => { "oidc" => "https://token.actions.githubusercontent.com" },
                         "conditions" => [
                           { "operator" => "string_matches", "claim" => "sub", "value" => "repo:example/repo:ref:refs/tags/.*" },
                           { "operator" => "string_equals", "claim" => "event_name", "value" => "" }
                         ]
                       }
                     ]
                   }
                 ), role.reload.as_json.slice(*expected.keys))
  end

  test "creating rubygem trusted publishers" do
    rubygem = create(:rubygem, name: "rubygem0")
    create(:version, rubygem: rubygem, metadata: { "source_code_uri" => "https://github.com/example/rubygem0" })

    visit new_rubygem_trusted_publisher_path(rubygem.slug)

    assert_text "Please sign in to continue."

    sign_in
    visit new_rubygem_trusted_publisher_path(rubygem.slug)
    verify_session

    assert_text "Forbidden"

    create(:ownership, rubygem: rubygem, user: @user)

    visit rubygem_trusted_publishers_path(rubygem.slug)

    assert_selector "h1", text: "Trusted Publishers"
    assert_text("Trusted publishers for rubygem0")
    assert_text "NO RUBYGEM TRUSTED PUBLISHERS FOUND"

    stub_request(:get, "https://api.github.com/repos/example/rubygem0/contents/.github/workflows")
      .to_return(status: 200, body: [
        { name: "ci.yml", type: "file" },
        { name: "push_rubygem.yml", type: "file" },
        { name: "push_README.md", type: "file" },
        { name: "push.yml", type: "directory" }
      ].to_json, headers: { "Content-Type" => "application/json" })

    click_button "Create"

    assert_selector "h1", text: "New Trusted Publisher"

    assert_field "Repository owner", with: "example"
    assert_field "Repository name", with: "rubygem0"
    assert_field "Workflow filename", with: "push_rubygem.yml"
    assert_field "Environment", with: ""

    stub_request(:get, "https://api.github.com/users/example")
      .to_return(status: 200, body: { id: "54321" }.to_json, headers: { "Content-Type" => "application/json" })

    click_button "Create Rubygem trusted publisher"

    assert_text "Trusted Publisher created"
    assert_selector "h1", text: "Trusted Publishers"
    assert_text("Trusted publishers for rubygem0")
    assert_text "GitHub Actions\nDelete\nGitHub Repository\nexample/rubygem0\nWorkflow Filename\npush_rubygem.yml"
  end

  test "deleting rubygem trusted publishers" do
    rubygem = create(:rubygem, owners: [@user])
    create(:oidc_rubygem_trusted_publisher, rubygem:)
    create(:version, rubygem:)

    sign_in
    visit rubygem_trusted_publishers_path(rubygem.slug)
    verify_session

    click_button "Delete"

    assert_content "Trusted Publisher deleted"
    assert_content "NO RUBYGEM TRUSTED PUBLISHERS FOUND"
  end

  test "creating pending trusted publishers" do
    rubygem = create(:rubygem, name: "rubygem0")
    create(:version, rubygem: rubygem, metadata: { "source_code_uri" => "https://github.com/example/rubygem0" })

    visit profile_oidc_pending_trusted_publishers_path

    assert_text "Please sign in to continue."

    sign_in
    visit profile_oidc_pending_trusted_publishers_path
    verify_session
    click_button "Create"

    assert_selector "h1", text: "New Pending Trusted Publisher"

    click_button "Create"

    assert_text "can't be blank"
    assert_selector "h1", text: "New Pending Trusted Publisher"

    fill_in "RubyGem name", with: "rubygem0"
    fill_in "Repository owner", with: "example"
    fill_in "Repository name", with: "rubygem1"
    fill_in "Workflow filename", with: "push_rubygem.yml"
    fill_in "Environment", with: "prod"

    stub_request(:get, "https://api.github.com/users/example")
      .to_return(status: 200, body: { id: "54321" }.to_json, headers: { "Content-Type" => "application/json" })

    click_button "Create"

    assert_text "RubyGem name is already in use"
    assert_selector "h1", text: "New Pending Trusted Publisher"

    assert_field "RubyGem name", with: "rubygem0"
    assert_field "Repository owner", with: "example"
    assert_field "Repository name", with: "rubygem1"
    assert_field "Workflow filename", with: "push_rubygem.yml"
    assert_field "Environment", with: "prod"

    fill_in "RubyGem name", with: "rubygem1"

    click_button "Create Pending trusted publisher"

    assert_text "Pending Trusted Publisher created"
    assert_selector "h1", text: "Pending Trusted Publishers"
    assert_text <<~TEXT
      rubygem1
      Delete
      GitHub Actions
      Valid for about 12 hours
      GitHub Repository
      example/rubygem1
      Workflow Filename
      push_rubygem.yml
      Environment
      prod
    TEXT
  end

  test "deleting pending trusted publishers" do
    create(:oidc_pending_trusted_publisher, user: @user)

    sign_in
    visit profile_oidc_pending_trusted_publishers_path
    verify_session

    click_button "Delete"

    assert_content "Pending Trusted Publisher deleted"
    assert_content "NO PENDING TRUSTED PUBLISHERS FOUND"
  end
end
