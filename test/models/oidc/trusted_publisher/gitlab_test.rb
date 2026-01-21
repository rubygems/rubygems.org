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
      ref: "refs/heads/main"
    }

    assert_equal branch_publisher, OIDC::TrustedPublisher::GitLab.for_claims(claims)
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

  test "#to_access_policy" do
    publisher = create(:oidc_trusted_publisher_gitlab,
      project_path: "myns/rubygem1",
      ci_config_path: ".gitlab-ci.yml",
      ref_type: "branch",
      branch_name: "main")

    jwt = { ref: "refs/heads/main", sha: "abc123" }

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
