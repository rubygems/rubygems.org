require "test_helper"

class OIDC::TrustedPublisher::GitHubActionTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should have_many(:rubygems)
  should have_many(:rubygem_trusted_publishers)
  should have_many(:api_keys).inverse_of(:owner)

  should validate_presence_of(:repository_owner)
  should validate_presence_of(:repository_name)
  should validate_presence_of(:workflow_filename)
  should validate_presence_of(:repository_owner_id)

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

    assert_equal(
      {
        statements: [
          {
            effect: "allow",
            principal: {
              oidc: "https://token.actions.githubusercontent.com"
            },
            conditions: [
              { operator: "string_equals", claim: "repository", value: "example/rubygem1" },
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
              { operator: "string_equals", claim: "repository_owner_id", value: "123456" },
              { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
              { operator: "string_equals", claim: "job_workflow_ref", value: "example/rubygem1/.github/workflows/push_gem.yml@sha" }
            ]
          }
        ]
      }.deep_stringify_keys,
      publisher.to_access_policy({ ref: "ref", sha: "sha" }).as_json
    )

    publisher.update!(environment: "test")

    assert_equal(
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
end
