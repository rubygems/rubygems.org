require "test_helper"

class OIDC::TrustedPublisher::GitLabTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should have_many(:rubygems)
  should have_many(:rubygem_trusted_publishers)
  should have_many(:api_keys).inverse_of(:owner)

  context "validations" do
    should validate_presence_of(:project_path)
    should validate_length_of(:project_path).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_presence_of(:ref_path)
    should validate_length_of(:ref_path).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_length_of(:environment).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_length_of(:ci_config_ref_uri).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
  end

  test "validates publisher uniqueness" do
    publisher = create(:oidc_trusted_publisher_gitlab)
    assert_raises(ActiveRecord::RecordInvalid) do
      create(:oidc_trusted_publisher_gitlab, project_path: publisher.project_path, ref_path: publisher.ref_path)
    end
  end

  test ".for_claims" do
    bar = create(:oidc_trusted_publisher_gitlab, project_path: "bar", ref_path: "refs/heads/main")
    create(:oidc_trusted_publisher_gitlab, project_path: "foo", ref_path: "refs/heads/main")

    claims = {
      project_path: "bar",
      ref_path: "refs/heads/main"
    }

    assert_equal bar, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".build_trusted_publisher" do
    existing_publisher = create(:oidc_trusted_publisher_gitlab,
                               project_path: "test-repo",
                               ref_path: "refs/heads/main")

    # Test returning existing record when params match
    result = OIDC::TrustedPublisher::GitLab.build_trusted_publisher(
      project_path: "test-repo",
      ref_path: "refs/heads/main"
    )

    assert_equal existing_publisher, result
    refute_predicate result, :new_record?

    # Test building new record when no existing record matches
    another_new_publisher = OIDC::TrustedPublisher::GitLab.build_trusted_publisher(
      project_path: "different-repo",
      ref_path: "refs/heads/main"
    )

    assert_predicate another_new_publisher, :new_record?
    assert_equal "different-repo", another_new_publisher.project_path
    assert_equal "refs/heads/main", another_new_publisher.ref_path
  end

  test "#name" do
    publisher = create(:oidc_trusted_publisher_gitlab, project_path: "bar")

    assert_equal "GitLab bar", publisher.name
  end

  test "#to_access_policy" do
    publisher = create(:oidc_trusted_publisher_gitlab, project_path: "rubygem1", ref_path: "refs/heads/main")

    assert_equal_hash(
      {
        statements: [
          { effect: "allow",
            principal: {
              oidc: "https://gitlab.com"
            },
            conditions: [
              { operator: "string_equals", claim: "project_path", value: "rubygem1" },
              { operator: "string_equals", claim: "ref_path", value: "refs/heads/main" }
            ] }
        ]
      }.deep_stringify_keys,
      publisher.to_access_policy({}).as_json
    )
  end
end
