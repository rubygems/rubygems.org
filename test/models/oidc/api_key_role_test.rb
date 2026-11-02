# frozen_string_literal: true

require "test_helper"

class OIDC::ApiKeyRoleTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should belong_to :provider
  should belong_to :user
  should have_many :id_tokens
  should validate_presence_of :api_key_permissions
  should validate_presence_of :access_policy
  should validate_presence_of :name
  should validate_length_of(:name).is_at_most(Gemcutter::MAX_FIELD_LENGTH)

  setup do
    @role = build(:oidc_api_key_role)
  end

  test "inspect with nested attributes" do
    assert_match "string_equals", @role.inspect
  end

  test "pretty_inspect with nested attributes" do
    assert_match "string_equals", @role.pretty_inspect
  end

  test "for_rubygem scope" do
    user = @role.user
    rubygem = create(:rubygem, owners: [user])
    rubygem_role = create(:oidc_api_key_role, api_key_permissions: { gems: [rubygem.name], scopes: ["push_rubygem"] }, user:)
    create(:oidc_api_key_role, api_key_permissions: { gems: [create(:rubygem, owners: [user]).name], scopes: ["push_rubygem"] }, user:)
    empty_gems = create(:oidc_api_key_role, api_key_permissions: { gems: [], scopes: ["push_rubygem"] }, user:)
    nil_gems = create(:oidc_api_key_role, api_key_permissions: { gems: nil, scopes: ["push_rubygem"] }, user:)

    assert_same_elements [rubygem_role], OIDC::ApiKeyRole.for_rubygem(rubygem).to_a
    assert_same_elements [@role, empty_gems, nil_gems], OIDC::ApiKeyRole.for_rubygem(nil).to_a
  end

  test "for_scope scope" do
    role1 = create(:oidc_api_key_role, api_key_permissions: { gems: [], scopes: %w[push_rubygem yank_rubygem] })
    role2 = create(:oidc_api_key_role, api_key_permissions: { gems: [], scopes: ["push_rubygem"] })

    assert_same_elements [role1, role2], OIDC::ApiKeyRole.for_scope("push_rubygem").to_a
    assert_same_elements [role1], OIDC::ApiKeyRole.for_scope("yank_rubygem").to_a
    assert_predicate OIDC::ApiKeyRole.for_scope("show_dashboard"), :none?
  end

  test "validates gems belong to the user" do
    @role.api_key_permissions.gems = ["does_not_exist"]
    @role.validate

    assert_equal ["(does_not_exist) does not belong to user #{@role.user.handle}"], @role.errors.messages[:"api_key_permissions.gems[0]"]
  end

  test "validates condition claims are known" do
    @role.access_policy.statements = [OIDC::AccessPolicy::Statement.new(
      effect: "allow",
      conditions: [
        operator: "string_equals", claim: "unknown", value: ""
      ],
      principal: { oidc: "" }
    )]
    @role.validate

    assert_equal ["unknown for the provider"], @role.errors.messages[:"access_policy.statements[0].conditions[0].claim"]
  end

  test "validates nested models" do
    @role.access_policy.statements = [OIDC::AccessPolicy::Statement.new(
      principal: { oidc: nil }
    )]
    @role.provider = nil
    @role.validate

    assert_equal ["can't be blank"], @role.errors.messages[:"access_policy.statements[0].principal.oidc"]
  end

  context "recording access policy changes" do
    setup do
      @role = create(:oidc_api_key_role)
      @policy = { statements: [
        effect: "allow", conditions: [operator: "string_equals", claim: "repository", value: "fakeuser/oidc-test"]
      ] }
    end

    should "record an event for the owner of the role" do
      Current.user = @role.user
      @role.update!(access_policy: @policy)

      event = access_policy_events.sole

      assert_equal @role.user, event.user
      assert_equal @role.name, event.additional.name
      assert_equal @role.to_global_id, event.additional.api_key_role_gid
      assert_predicate event.additional, :by_owner
      assert_equal ["repository string_equals fakeuser/oidc-test"], event.additional.conditions
    end

    should "record that someone other than the owner changed it" do
      Current.user = create(:user)
      @role.update!(access_policy: @policy)

      refute_predicate access_policy_events.sole.additional, :by_owner
    end

    should "keep the request details when the owner changed it" do
      Current.user = @role.user
      Current.request = request_with_ip

      @role.update!(access_policy: @policy)
      event = access_policy_events.sole

      assert_equal "1.2.3.4", event.ip_address.ip_address.to_s
      assert_predicate event.additional.user_agent_info, :present?
    end

    # The owner can read this event, and the events table renders the request's
    # address and user agent to them, so an admin's must not be attached.
    should "withhold the request details when someone else changed it" do
      Current.user = create(:user)
      Current.request = request_with_ip

      @role.update!(access_policy: @policy)
      event = access_policy_events.sole

      assert_nil event.ip_address
      assert_nil event.geoip_info
      assert_nil event.additional.user_agent_info
    end

    should "record nothing when the access policy does not change" do
      @role.update!(name: "Renamed without touching the access policy")

      assert_empty access_policy_events
    end

    should "record nothing when the update is rejected" do
      refute @role.update(access_policy: { statements: [
                            effect: "allow", conditions: [operator: "string_equals", claim: "unknown_claim", value: "anything"]
                          ] })
      assert_empty access_policy_events
    end
  end

  def github_actions_role(conditions:, scopes: ["push_rubygem"], effect: "allow")
    provider = build(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER)
    build(:oidc_api_key_role, provider:,
      api_key_permissions: { scopes: },
      access_policy: { statements: [effect:, principal: { oidc: provider.issuer }, conditions:] })
  end

  test "a GitHub Actions gem role whose policy only checks aud is invalid" do
    role = github_actions_role(conditions: [operator: "string_equals", claim: "aud", value: Gemcutter::HOST])

    refute_predicate role, :valid?
    assert_match "must bind the token to a repository", role.errors.messages[:access_policy].join
  end

  test "a GitHub Actions gem role bound by repository is valid" do
    role = github_actions_role(
      conditions: [
        { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
        { operator: "string_equals", claim: "repository", value: "example/repo" }
      ]
    )

    assert_predicate role, :valid?
  end

  test "a GitHub Actions gem role bound by an exact repo-scoped sub is valid" do
    role = github_actions_role(
      conditions: [operator: "string_equals", claim: "sub", value: "repo:example/repo:ref:refs/heads/main"]
    )

    assert_predicate role, :valid?
  end

  test "a GitHub Actions gem role bound by an immutable (repo:owner@id/repo@id) sub is valid" do
    role = github_actions_role(
      conditions: [operator: "string_equals", claim: "sub", value: "repo:example@123/repo@456:ref:refs/heads/main"]
    )

    assert_predicate role, :valid?
  end

  test "a GitHub Actions gem role bound only by workflow metadata is invalid" do
    %w[job_workflow_ref job_workflow_sha workflow_ref].each do |claim|
      role = github_actions_role(
        conditions: [operator: "string_equals", claim:, value: "example/repo/.github/workflows/release.yml@refs/heads/main"]
      )

      refute_predicate role, :valid?, "#{claim} identifies workflow metadata, not a trusted caller"
    end
  end

  test "a GitHub Actions gem role bound only by a pattern-matched sub is invalid" do
    # `sub` is caller-customizable, so a pattern match is not a reliable binding.
    role = github_actions_role(
      conditions: [operator: "string_matches", claim: "sub", value: "repo:example/.*"]
    )

    refute_predicate role, :valid?
  end

  test "a GitHub Actions gem role bound only by a customized repo-less sub is invalid" do
    # A subject customized to drop the repository (e.g. just the environment)
    # does not tie the token to a repository.
    role = github_actions_role(
      conditions: [operator: "string_equals", claim: "sub", value: "environment:production"]
    )

    refute_predicate role, :valid?
  end

  test "a GitHub Actions gem role bound only by a blank repository value is invalid" do
    role = github_actions_role(
      conditions: [
        { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
        { operator: "string_equals", claim: "repository", value: "" }
      ]
    )

    refute_predicate role, :valid?
  end

  test "a GitHub Actions gem role bound only by a deny statement is invalid" do
    provider = build(:oidc_provider, issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER)
    role = build(:oidc_api_key_role, provider:,
      api_key_permissions: { scopes: ["push_rubygem"] },
      access_policy: { statements: [
        { effect: "allow", principal: { oidc: provider.issuer },
          conditions: [operator: "string_equals", claim: "aud", value: Gemcutter::HOST] },
        { effect: "deny", principal: { oidc: provider.issuer },
          conditions: [operator: "string_equals", claim: "repository", value: "example/repo"] }
      ] })

    refute_predicate role, :valid?
  end

  test "a GitHub Actions role without gem-applicable scopes need not bind a repository" do
    role = github_actions_role(
      scopes: ["index_rubygems"],
      conditions: [operator: "string_equals", claim: "aud", value: Gemcutter::HOST]
    )

    assert_predicate role, :valid?
  end

  def buildkite_role(conditions:, scopes: ["push_rubygem"], effect: "allow")
    provider = build(:oidc_provider_buildkite, issuer: OIDC::Provider::BUILDKITE_ISSUER)
    build(:oidc_api_key_role, provider:,
      api_key_permissions: { scopes: },
      access_policy: { statements: [effect:, principal: { oidc: provider.issuer }, conditions:] })
  end

  test "a Buildkite gem role whose policy only checks aud is invalid" do
    role = buildkite_role(conditions: [operator: "string_equals", claim: "aud", value: Gemcutter::HOST])

    refute_predicate role, :valid?
    assert_match "constrain one of organization_id, organization_slug, pipeline_id", role.errors.messages[:access_policy].join
  end

  test "a Buildkite gem role bound by organization_slug is valid" do
    role = buildkite_role(
      conditions: [
        { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
        { operator: "string_equals", claim: "organization_slug", value: "example-org" }
      ]
    )

    assert_predicate role, :valid?
  end

  test "a Buildkite gem role bound by organization_id is valid" do
    role = buildkite_role(
      conditions: [operator: "string_equals", claim: "organization_id", value: "0191e39d-8a93-77be-a1fe-934a3d9e1bc8"]
    )

    assert_predicate role, :valid?
  end

  test "a Buildkite gem role bound by pipeline_id is valid" do
    role = buildkite_role(
      conditions: [operator: "string_equals", claim: "pipeline_id", value: "0191e39d-c89c-7c33-a1db-f16e1cfa229f"]
    )

    assert_predicate role, :valid?
  end

  test "a Buildkite gem role bound only by an organization-scoped sub is invalid" do
    # Unlike GitHub, Buildkite bindings must use the organization/pipeline
    # claims; a sub is not accepted even when it pins the organization.
    role = buildkite_role(
      conditions: [
        operator: "string_equals", claim: "sub",
        value: "organization:example-org:pipeline:example-pipeline:ref:refs/heads/main:commit:b5ffe3aeea51cec6c41aef16e45ee6bce47d8810:step:"
      ]
    )

    refute_predicate role, :valid?
  end

  test "a Buildkite gem role bound only by pipeline_slug is invalid" do
    # Any Buildkite organization can name a pipeline to match, so a pipeline
    # slug does not bind the token without an organization claim.
    role = buildkite_role(
      conditions: [
        { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
        { operator: "string_equals", claim: "pipeline_slug", value: "example-pipeline" }
      ]
    )

    refute_predicate role, :valid?
  end

  test "a Buildkite gem role bound only by build_branch is invalid" do
    role = buildkite_role(
      conditions: [operator: "string_equals", claim: "build_branch", value: "main"]
    )

    refute_predicate role, :valid?
  end

  test "a Buildkite gem role bound only by a pattern-matched sub is invalid" do
    role = buildkite_role(
      conditions: [operator: "string_matches", claim: "sub", value: "organization:example-org:.*"]
    )

    refute_predicate role, :valid?
  end

  test "a Buildkite gem role bound only by a sub that does not pin an organization is invalid" do
    role = buildkite_role(
      conditions: [operator: "string_equals", claim: "sub", value: "pipeline:example-pipeline:ref:refs/heads/main"]
    )

    refute_predicate role, :valid?
  end

  test "a Buildkite role without gem-applicable scopes need not bind an organization" do
    role = buildkite_role(
      scopes: ["index_rubygems"],
      conditions: [operator: "string_equals", claim: "aud", value: Gemcutter::HOST]
    )

    assert_predicate role, :valid?
  end

  def unknown_provider_role(conditions:, scopes: ["push_rubygem"], effect: "allow")
    provider = build(:oidc_provider, issuer: "https://oidc.example.com")
    build(:oidc_api_key_role, provider:,
      api_key_permissions: { scopes: },
      access_policy: { statements: [effect:, principal: { oidc: provider.issuer }, conditions:] })
  end

  test "an unknown-provider gem role bound by an exact sub is valid" do
    role = unknown_provider_role(
      conditions: [operator: "string_equals", claim: "sub", value: "service-account:releases"]
    )

    assert_predicate role, :valid?
  end

  test "an unknown-provider gem role bound only by claims other than sub is invalid" do
    role = unknown_provider_role(
      conditions: [
        { operator: "string_equals", claim: "aud", value: Gemcutter::HOST },
        { operator: "string_equals", claim: "actor", value: "releaser" }
      ]
    )

    refute_predicate role, :valid?
    assert_match "constrain an exact `sub` claim", role.errors.messages[:access_policy].join
  end

  test "a non-GitHub gem role bound by a provider-specific claim is valid" do
    # The buildkite factory's default policy binds organization_slug (a non-boilerplate claim).
    assert_predicate build(:oidc_api_key_role_buildkite), :valid?
  end

  test "a non-GitHub gem role whose policy only checks aud is invalid" do
    role = build(:oidc_api_key_role_buildkite,
      access_policy: { statements: [
        effect: "allow",
        conditions: [operator: "string_equals", claim: "aud", value: Gemcutter::HOST]
      ] })

    refute_predicate role, :valid?
    assert_match "must bind the token to a specific workload", role.errors.messages[:access_policy].join
  end

  test "a non-GitHub gem role cannot bind only a wildcard claim" do
    role = build(:oidc_api_key_role_buildkite,
      access_policy: { statements: [
        effect: "allow",
        conditions: [operator: "string_matches", claim: "organization_slug", value: ".*"]
      ] })

    refute_predicate role, :valid?
  end

  test "a non-GitHub role without gem-applicable scopes need not bind a workload" do
    role = build(:oidc_api_key_role_buildkite,
      api_key_permissions: { scopes: ["index_rubygems"] },
      access_policy: { statements: [
        effect: "allow",
        conditions: [operator: "string_equals", claim: "aud", value: Gemcutter::HOST]
      ] })

    assert_predicate role, :valid?
  end

  test "a Buildkite role bound only by a branch cannot authorize another organization" do
    role = build(:oidc_api_key_role_buildkite,
      access_policy: { statements: [
        effect: "allow",
        conditions: [operator: "string_equals", claim: "build_branch", value: "main"]
      ] })

    refute_predicate role, :valid?
  end

  private

  def request_with_ip
    ActionDispatch::TestRequest.create(
      "REMOTE_ADDR" => "1.2.3.4",
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh) AppleWebKit/537.36 Chrome/120.0 Safari/537.36"
    )
  end

  def access_policy_events
    @role.user.events.where(tag: Events::UserEvent::OIDC_API_KEY_ROLE_ACCESS_POLICY_CHANGED)
  end
end
