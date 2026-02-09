require "test_helper"

class OIDC::TrustedPublisher::GitHubActionTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should have_many(:rubygems)
  should have_many(:rubygem_trusted_publishers)
  should have_many(:api_keys).inverse_of(:owner)

  context "validations" do
    setup do
      stub_request(:get, Addressable::Template.new("https://api.github.com/users/{user}"))
        .to_return(status: 404, body: "", headers: {})
    end
    should validate_presence_of(:repository_owner)
    should validate_length_of(:repository_owner).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_presence_of(:repository_name)
    should validate_length_of(:repository_name).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_presence_of(:workflow_filename)
    should validate_length_of(:workflow_filename).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_presence_of(:repository_owner_id)
    should validate_length_of(:repository_owner_id).is_at_most(Gemcutter::MAX_FIELD_LENGTH)

    should validate_length_of(:environment).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
  end

  test "validates publisher uniqueness" do
    publisher = create(:oidc_trusted_publisher_github_action)
    assert_raises(ActiveRecord::RecordInvalid) do
      create(:oidc_trusted_publisher_github_action, repository_owner: publisher.repository_owner,
            repository_name: publisher.repository_name, workflow_filename: publisher.workflow_filename,
            repository_owner_id: publisher.repository_owner_id, environment: publisher.environment)
    end
  end

  test ".for_claims" do
    bar_other_owner_id = create(:oidc_trusted_publisher_github_action, repository_name: "bar")
    bar_other_owner_id.update!(repository_owner_id: "654321")
    bar = create(:oidc_trusted_publisher_github_action, repository_name: "bar")
    bar_test = create(:oidc_trusted_publisher_github_action, repository_name: "bar", environment: "test")
    _bar_dev = create(:oidc_trusted_publisher_github_action, repository_name: "bar", environment: "dev")
    create(:oidc_trusted_publisher_github_action, repository_name: "foo")

    claims = {
      repository: "example/bar",
      job_workflow_ref: "example/bar/.github/workflows/push_gem.yml@refs/heads/main",
      ref: "refs/heads/main",
      sha: "04de3558bc5861874a86f8fcd67e516554101e71",
      repository_owner_id: "123456"
    }

    assert_equal bar,      OIDC::TrustedPublisher::GitHubAction.for_claims(claims)
    assert_equal bar,      OIDC::TrustedPublisher::GitHubAction.for_claims(claims.merge(environment: nil))
    assert_equal bar,      OIDC::TrustedPublisher::GitHubAction.for_claims(claims.merge(environment: "other"))
    assert_equal bar_test, OIDC::TrustedPublisher::GitHubAction.for_claims(claims.merge(environment: "test"))
  end

  test ".build_trusted_publisher" do
    stub_request(:get, "https://api.github.com/users/example")
      .to_return(status: 200, body: { id: "54321" }.to_json, headers: { "Content-Type" => "application/json" })

    existing_publisher = create(:oidc_trusted_publisher_github_action,
                               repository_owner: "example",
                               repository_name: "test-repo",
                               workflow_filename: "ci.yml",
                               environment: "production")

    # Test returning existing record when params match
    result = OIDC::TrustedPublisher::GitHubAction.build_trusted_publisher(
      repository_owner: "example",
      repository_name: "test-repo",
      workflow_filename: "ci.yml",
      environment: "production"
    )

    assert_equal existing_publisher, result
    refute_predicate result, :new_record?

    # Test building new record when environment is blank
    new_publisher = OIDC::TrustedPublisher::GitHubAction.build_trusted_publisher(
      repository_owner: "example",
      repository_name: "test-repo",
      workflow_filename: "ci.yml",
      environment: ""
    )

    refute_equal existing_publisher, new_publisher
    assert_predicate new_publisher, :new_record?
    assert_nil new_publisher.environment

    # Test building new record when no existing record matches
    another_new_publisher = OIDC::TrustedPublisher::GitHubAction.build_trusted_publisher(
      repository_owner: "different-owner",
      repository_name: "different-repo",
      workflow_filename: "deploy.yml",
      environment: ""
    )

    assert_predicate another_new_publisher, :new_record?
    assert_equal "different-owner", another_new_publisher.repository_owner
    assert_equal "different-repo", another_new_publisher.repository_name
  end

  test "#name" do
    publisher = create(:oidc_trusted_publisher_github_action, repository_name: "bar")

    assert_equal "GitHub Actions example/bar @ .github/workflows/push_gem.yml", publisher.name

    publisher.update!(environment: "test")

    assert_equal "GitHub Actions example/bar @ .github/workflows/push_gem.yml (test)", publisher.name
  end

  test "#owns_gem?" do
    rubygem1 = create(:rubygem)
    rubygem2 = create(:rubygem)

    publisher = create(:oidc_trusted_publisher_github_action)
    create(:oidc_rubygem_trusted_publisher, trusted_publisher: publisher, rubygem: rubygem1)

    assert publisher.owns_gem?(rubygem1)
    refute publisher.owns_gem?(rubygem2)
  end

  test "#to_access_policy" do
    publisher = create(:oidc_trusted_publisher_github_action, repository_name: "rubygem1")

    assert_equal_hash(
      {
        statements: [
          { effect: "allow",
            principal: {
              oidc: "https://token.actions.githubusercontent.com"
            },
            conditions: [
              { operator: "string_equals", claim: "repository", value: "example/rubygem1" },
              { operator: "string_equals", claim: "repository_owner_id", value: "123456" },
              { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
              { operator: "string_equals", claim: "job_workflow_ref", value: "example/rubygem1/.github/workflows/push_gem.yml@ref" }
            ] },
          { effect: "allow",
            principal: {
              oidc: "https://token.actions.githubusercontent.com"
            },
            conditions: [
              { operator: "string_equals", claim: "repository", value: "example/rubygem1" },
              { operator: "string_equals", claim: "repository_owner_id", value: "123456" },
              { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
              { operator: "string_equals", claim: "job_workflow_ref", value: "example/rubygem1/.github/workflows/push_gem.yml@sha" }
            ] }
        ]
      }.deep_stringify_keys,
      publisher.to_access_policy({ ref: "ref", sha: "sha" }).as_json
    )

    publisher.update!(environment: "test")

    assert_equal_hash(
      {
        statements: [
          {
            effect: "allow",
            principal: {
              oidc: "https://token.actions.githubusercontent.com"
            },
            conditions: [
              { operator: "string_equals", claim: "repository", value: "example/rubygem1" },
              { operator: "string_equals", claim: "environment", value: "test" },
              { operator: "string_equals", claim: "repository_owner_id", value: "123456" },
              { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
              { operator: "string_equals", claim: "job_workflow_ref", value: "example/rubygem1/.github/workflows/push_gem.yml@ref" }
            ]
          },
          {
            effect: "allow",
            principal: {
              oidc: "https://token.actions.githubusercontent.com"
            },
            conditions: [
              { operator: "string_equals", claim: "repository", value: "example/rubygem1" },
              { operator: "string_equals", claim: "environment", value: "test" },
              { operator: "string_equals", claim: "repository_owner_id", value: "123456" },
              { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
              { operator: "string_equals", claim: "job_workflow_ref", value: "example/rubygem1/.github/workflows/push_gem.yml@sha" }
            ]
          }
        ]
      }.deep_stringify_keys,
      publisher.to_access_policy({ ref: "ref", sha: "sha" }).as_json
    )
  end

  test ".for_claims with reusable workflow from different repository" do
    # Publisher configured for reusable workflow: caller is example/caller-repo,
    # but workflow is from shared-org/shared-workflows
    reusable_publisher = create(:oidc_trusted_publisher_github_action,
      repository_owner: "example",
      repository_name: "caller-repo",
      workflow_filename: "shared-release.yml",
      workflow_repository_owner: "shared-org",
      workflow_repository_name: "shared-workflows")

    claims = {
      repository: "example/caller-repo",
      job_workflow_ref: "shared-org/shared-workflows/.github/workflows/shared-release.yml@refs/heads/main",
      ref: "refs/heads/main",
      sha: "abc123def456",
      repository_owner_id: "123456"
    }

    assert_equal reusable_publisher, OIDC::TrustedPublisher::GitHubAction.for_claims(claims)
  end

  test ".for_claims rejects reusable workflow when caller repository does not match" do
    # Publisher configured for specific caller repo
    create(:oidc_trusted_publisher_github_action,
      repository_owner: "allowed-org",
      repository_name: "allowed-repo",
      workflow_filename: "shared-release.yml",
      workflow_repository_owner: "shared-org",
      workflow_repository_name: "shared-workflows")

    # Attacker tries to use the same shared workflow from a different repo
    claims = {
      repository: "attacker-org/attacker-repo",
      job_workflow_ref: "shared-org/shared-workflows/.github/workflows/shared-release.yml@refs/heads/main",
      ref: "refs/heads/main",
      sha: "abc123def456",
      repository_owner_id: "999999"
    }

    assert_raises(ActiveRecord::RecordNotFound) do
      OIDC::TrustedPublisher::GitHubAction.for_claims(claims)
    end
  end

  test ".for_claims works with same-repo workflow when workflow_repository is nil" do
    # Standard publisher without workflow_repository set (backward compatible)
    standard_publisher = create(:oidc_trusted_publisher_github_action,
      repository_owner: "example",
      repository_name: "my-gem",
      workflow_filename: "release.yml",
      workflow_repository_owner: nil,
      workflow_repository_name: nil)

    claims = {
      repository: "example/my-gem",
      job_workflow_ref: "example/my-gem/.github/workflows/release.yml@refs/heads/main",
      ref: "refs/heads/main",
      sha: "abc123",
      repository_owner_id: "123456"
    }

    assert_equal standard_publisher, OIDC::TrustedPublisher::GitHubAction.for_claims(claims)
  end

  test "validates workflow_repository_fields must both be present or both be blank" do
    stub_request(:get, "https://api.github.com/users/example")
      .to_return(status: 200, body: { id: "123456" }.to_json, headers: { "Content-Type" => "application/json" })

    # Both set - valid
    publisher = OIDC::TrustedPublisher::GitHubAction.new(
      repository_owner: "example",
      repository_name: "repo",
      workflow_filename: "release.yml",
      workflow_repository_owner: "shared",
      workflow_repository_name: "workflows"
    )

    assert_predicate publisher, :valid?

    # Both nil - valid
    publisher = OIDC::TrustedPublisher::GitHubAction.new(
      repository_owner: "example",
      repository_name: "repo",
      workflow_filename: "release.yml",
      workflow_repository_owner: nil,
      workflow_repository_name: nil
    )

    assert_predicate publisher, :valid?

    # Only owner set - invalid
    publisher = OIDC::TrustedPublisher::GitHubAction.new(
      repository_owner: "example",
      repository_name: "repo",
      workflow_filename: "release.yml",
      workflow_repository_owner: "shared",
      workflow_repository_name: nil
    )

    refute_predicate publisher, :valid?
    assert_includes publisher.errors[:workflow_repository_name], "can't be blank"

    # Only name set - invalid
    publisher = OIDC::TrustedPublisher::GitHubAction.new(
      repository_owner: "example",
      repository_name: "repo",
      workflow_filename: "release.yml",
      workflow_repository_owner: nil,
      workflow_repository_name: "workflows"
    )

    refute_predicate publisher, :valid?
    assert_includes publisher.errors[:workflow_repository_owner], "can't be blank"
  end

  test "validates workflow_repository_differs_from_repository" do
    stub_request(:get, "https://api.github.com/users/example")
      .to_return(status: 200, body: { id: "123456" }.to_json, headers: { "Content-Type" => "application/json" })

    # workflow_repository same as repository - invalid
    publisher = OIDC::TrustedPublisher::GitHubAction.new(
      repository_owner: "example",
      repository_name: "my-gem",
      workflow_filename: "release.yml",
      workflow_repository_owner: "example",
      workflow_repository_name: "my-gem"
    )

    refute_predicate publisher, :valid?
    assert_includes publisher.errors[:base], "workflow_repository must be different from the repository, leave blank for same-repository workflows"

    # workflow_repository different from repository - valid
    publisher = OIDC::TrustedPublisher::GitHubAction.new(
      repository_owner: "example",
      repository_name: "my-gem",
      workflow_filename: "release.yml",
      workflow_repository_owner: "shared-org",
      workflow_repository_name: "shared-workflows"
    )

    assert_predicate publisher, :valid?
  end

  test "#workflow_repository returns workflow repo when set" do
    publisher = create(:oidc_trusted_publisher_github_action,
      repository_owner: "caller-org",
      repository_name: "caller-repo",
      workflow_repository_owner: "shared-org",
      workflow_repository_name: "shared-repo")

    assert_equal "shared-org/shared-repo", publisher.workflow_repository
  end

  test "#workflow_repository returns caller repo when workflow repo not set" do
    publisher = create(:oidc_trusted_publisher_github_action,
      repository_owner: "example",
      repository_name: "my-gem",
      workflow_repository_owner: nil,
      workflow_repository_name: nil)

    assert_equal "example/my-gem", publisher.workflow_repository
  end

  test "#to_access_policy with reusable workflow" do
    publisher = create(:oidc_trusted_publisher_github_action,
      repository_owner: "caller-org",
      repository_name: "caller-repo",
      workflow_filename: "shared-release.yml",
      workflow_repository_owner: "shared-org",
      workflow_repository_name: "shared-workflows")

    policy = publisher.to_access_policy({ ref: "refs/heads/main", sha: "abc123" })

    # Verify job_workflow_ref points to the shared workflow repo, not the caller repo
    first_statement = policy.statements.first
    job_workflow_ref_condition = first_statement.conditions.find { |c| c.claim == "job_workflow_ref" }

    assert_equal "shared-org/shared-workflows/.github/workflows/shared-release.yml@refs/heads/main",
                 job_workflow_ref_condition.value

    # Verify repository condition still points to caller repo (security)
    repository_condition = first_statement.conditions.find { |c| c.claim == "repository" }

    assert_equal "caller-org/caller-repo", repository_condition.value
  end
end
