require "test_helper"

class OIDC::TrustedPublisher::GitLabTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should have_many(:rubygems)
  should have_many(:rubygem_trusted_publishers)
  should have_many(:api_keys).inverse_of(:owner)

  context "validations" do
    should validate_presence_of(:namespace_path)
    should validate_length_of(:namespace_path).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
    should validate_presence_of(:project_path)
    should validate_length_of(:project_path).is_at_most(Gemcutter::MAX_FIELD_LENGTH)
  end

  test "validates publisher uniqueness" do
    publisher = create(:oidc_trusted_publisher_gitlab)
    assert_raises(ActiveRecord::RecordInvalid) do
      create(:oidc_trusted_publisher_gitlab, namespace_path: publisher.namespace_path,
            project_path: publisher.project_path)
    end
  end

  test ".for_claims" do
    bar = create(:oidc_trusted_publisher_gitlab, namespace_path: "example", project_path: "bar")
    create(:oidc_trusted_publisher_gitlab, namespace_path: "example", project_path: "foo")

    claims = {
      namespace_path: "example",
      project_path: "bar"
    }

    assert_equal bar, OIDC::TrustedPublisher::GitLab.for_claims(claims)
  end

  test ".build_trusted_publisher" do
    existing_publisher = create(:oidc_trusted_publisher_gitlab,
                               namespace_path: "example",
                               project_path: "test-repo")

    # Test returning existing record when params match
    result = OIDC::TrustedPublisher::GitLab.build_trusted_publisher(
      namespace_path: "example",
      project_path: "test-repo"
    )

    assert_equal existing_publisher, result
    refute_predicate result, :new_record?

    # Test building new record when no existing record matches
    another_new_publisher = OIDC::TrustedPublisher::GitLab.build_trusted_publisher(
      namespace_path: "different-owner",
      project_path: "different-repo"
    )

    assert_predicate another_new_publisher, :new_record?
    assert_equal "different-owner", another_new_publisher.namespace_path
    assert_equal "different-repo", another_new_publisher.project_path
  end

  test "#name" do
    publisher = create(:oidc_trusted_publisher_gitlab, namespace_path: "example", project_path: "bar")

    assert_equal "GitLab example/bar", publisher.name
  end

  test "#to_access_policy" do
    publisher = create(:oidc_trusted_publisher_gitlab, namespace_path: "example", project_path: "rubygem1")

    assert_equal_hash(
      {
        statements: [
          { effect: "allow",
            principal: {
              oidc: "https://gitlab.com"
            },
            conditions: [
              { operator: "string_equals", claim: "namespace_path", value: "example" },
              { operator: "string_equals", claim: "project_path", value: "rubygem1" },
              { operator: "string_equals", claim: "ref", value: "ref" },
              { operator: "string_equals", claim: "ref_type", value: "branch" }
            ] }
        ]
      }.deep_stringify_keys,
      publisher.to_access_policy({ ref: "ref", ref_type: "branch" }).as_json
    )
  end
end
