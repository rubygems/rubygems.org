# frozen_string_literal: true

require "test_helper"

class OIDC::TrustedPublisher::GitLabTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should have_many(:rubygems)
  should have_many(:rubygem_trusted_publishers)
  should have_many(:api_keys).inverse_of(:owner)

  context "validations" do
    should validate_presence_of(:project_path)
    should validate_length_of(:project_path).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_presence_of(:ci_config_path)
    should validate_length_of(:ci_config_path).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_length_of(:environment).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_length_of(:ref_type).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_length_of(:branch_name).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
  end

  test "validates publisher uniqueness" do
    publisher = create(:oidc_trusted_publisher_gitlab)
    assert_raises(ActiveRecord::RecordInvalid) do
      create(:oidc_trusted_publisher_gitlab,
        project_path: publisher.project_path,
        ci_config_path: publisher.ci_config_path)
    end
  end

  test "validates branch_name required when ref_type is branch" do
    publisher = build(:oidc_trusted_publisher_gitlab, ref_type: "branch", branch_name: nil)

    refute_predicate publisher, :valid?
    assert_includes publisher.errors[:branch_name], "is required when ref_type is 'branch'"
  end

  test "validates ref_type is branch or tag or nil" do
    assert_predicate build(:oidc_trusted_publisher_gitlab, ref_type: nil), :valid?
    assert_predicate build(:oidc_trusted_publisher_gitlab, ref_type: "tag"), :valid?
    assert_predicate build(:oidc_trusted_publisher_gitlab, ref_type: "branch", branch_name: "main"), :valid?

    publisher = build(:oidc_trusted_publisher_gitlab, ref_type: "commit")

    refute_predicate publisher, :valid?
    assert_includes publisher.errors[:ref_type], "is not included in the list"
  end

  test ".for_claims with basic claims" do
    bar = create(:oidc_trusted_publisher_gitlab, project_path: "ns/bar")
    create(:oidc_trusted_publisher_gitlab, project_path: "ns/foo")

    claims = {
      project_path: "ns/bar"
    }

    assert_equal bar, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".for_claims with branch ref" do
    branch_publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "ns/bar",
      ref_type: "branch",
      branch_name: "main")

    claims = {
      project_path: "ns/bar",
      ref_type: "branch",
      ref: "main",
      ref_path: "refs/heads/main"
    }

    assert_equal branch_publisher, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".for_claims with tag ref" do
    tag_publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "ns/bar",
      ref_type: "tag")

    claims = {
      project_path: "ns/bar",
      ref_type: "tag",
      ref: "v1.0.0",
      ref_path: "refs/tags/v1.0.0"
    }

    assert_equal tag_publisher, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".for_claims with tag ref falls back to publisher with no ref_type" do
    any_publisher = create(:oidc_trusted_publisher_gitlab, project_path: "ns/bar", ref_type: nil)

    claims = {
      project_path: "ns/bar",
      ref_type: "tag",
      ref: "v1.0.0",
      ref_path: "refs/tags/v1.0.0"
    }

    assert_equal any_publisher, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".for_claims with environment prefers specific environment over nil" do
    _any_env_publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "ns/bar",
      environment: nil)
    specific_env_publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "ns/bar",
      ci_config_path: "deploy.yml",
      environment: "production")

    claims = { project_path: "ns/bar", environment: "production" }

    assert_equal specific_env_publisher, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".for_claims with environment falls back to nil environment publisher" do
    any_env_publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "ns/bar",
      environment: nil)

    claims = { project_path: "ns/bar", environment: "staging" }

    assert_equal any_env_publisher, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".for_claims raises RecordNotFound when no publisher matches" do
    create(:oidc_trusted_publisher_gitlab, project_path: "ns/other")

    claims = { project_path: "ns/bar" }

    assert_raises ActiveRecord::RecordNotFound do
      OIDC::TrustedPublisher::GitLab.for_claims(claims)
    end
  end

  test ".for_claims with nested namespace" do
    nested = create(:oidc_trusted_publisher_gitlab,
      project_path: "company/dept/team/repo")

    claims = {
      project_path: "company/dept/team/repo"
    }

    assert_equal nested, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".build_trusted_publisher" do
    existing_publisher = create(:oidc_trusted_publisher_gitlab,
                               project_path: "test-ns/test-repo",
                               ci_config_path: ".gitlab-ci.yml")

    # Test returning existing record when params match
    result = OIDC::TrustedPublisher::GitLab.build_trusted_publisher(
      project_path: "test-ns/test-repo",
      ci_config_path: ".gitlab-ci.yml"
    )

    assert_equal existing_publisher, result
    refute_predicate result, :new_record?

    # Test building new record when no existing record matches
    another_new_publisher = OIDC::TrustedPublisher::GitLab.build_trusted_publisher(
      project_path: "different-ns/different-repo",
      ci_config_path: ".gitlab-ci.yml"
    )

    assert_predicate another_new_publisher, :new_record?
    assert_equal "different-ns/different-repo", another_new_publisher.project_path
    assert_equal ".gitlab-ci.yml", another_new_publisher.ci_config_path
  end

  test "#name" do
    publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "myns/bar",
      ci_config_path: ".gitlab-ci.yml")

    assert_equal "GitLab myns/bar @ .gitlab-ci.yml", publisher.name
  end

  test "#to_access_policy raises AccessError when ref_path and sha are both missing" do
    publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "myns/rubygem1",
      ci_config_path: ".gitlab-ci.yml")

    assert_raises OIDC::AccessPolicy::AccessError do
      publisher.to_access_policy({})
    end
  end

  test "#to_access_policy for tag ref" do
    publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "myns/rubygem1",
      ci_config_path: ".gitlab-ci.yml",
      ref_type: "tag")

    jwt = { ref: "v1.0.0", ref_path: "refs/tags/v1.0.0", sha: "abc123" }

    policy = publisher.to_access_policy(jwt)

    assert_equal 2, policy.statements.size

    conditions = policy.statements.first["conditions"]

    assert_includes conditions.pluck("claim"), "ref_type"
    type_condition = conditions.find { |c| c["claim"] == "ref_type" }

    assert_equal "tag", type_condition["value"]

    ci_condition = conditions.find { |c| c["claim"] == "ci_config_ref_uri" }

    assert_equal "gitlab.com/myns/rubygem1//.gitlab-ci.yml@refs/tags/v1.0.0", ci_condition["value"]

    refute_includes conditions.pluck("claim"), "ref"
  end

  test "#to_access_policy" do
    publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "myns/rubygem1",
      ci_config_path: ".gitlab-ci.yml",
      ref_type: "branch",
      branch_name: "main")

    jwt = { ref: "main", ref_path: "refs/heads/main", sha: "abc123" }

    policy = publisher.to_access_policy(jwt)

    assert_equal 2, policy.statements.size
    assert_equal "allow", policy.statements.first["effect"]
    assert_equal OIDC::Provider::GITLAB_ISSUER, policy.statements.first["principal"]["oidc"]

    conditions = policy.statements.first["conditions"]

    assert_includes conditions.pluck("claim"), "project_path"
    assert_includes conditions.pluck("claim"), "ci_config_ref_uri"
    assert_includes conditions.pluck("claim"), "aud"
    assert_includes conditions.pluck("claim"), "ref"
    assert_includes conditions.pluck("claim"), "ref_type"

    # Check that ci_config_ref_uri uses strict matching with host
    ci_condition = conditions.find { |c| c["claim"] == "ci_config_ref_uri" }

    assert_equal "string_equals", ci_condition["operator"]
    assert_equal "gitlab.com/myns/rubygem1//.gitlab-ci.yml@refs/heads/main", ci_condition["value"]

    # Check ref condition
    ref_condition = conditions.find { |c| c["claim"] == "ref" }

    assert_equal "string_equals", ref_condition["operator"]
    assert_equal "refs/heads/main", ref_condition["value"]

    # Check ref_type condition
    type_condition = conditions.find { |c| c["claim"] == "ref_type" }

    assert_equal "string_equals", type_condition["operator"]
    assert_equal "branch", type_condition["value"]

    # Verify nested policy values
    nested_publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "a/b/c",
      ci_config_path: ".gitlab-ci.yml")

    nested_policy = nested_publisher.to_access_policy(jwt)
    nested_conditions = nested_policy.statements.first["conditions"]

    assert_equal "a/b/c", nested_conditions.find { |c| c["claim"] == "project_path" }["value"]
  end
end
