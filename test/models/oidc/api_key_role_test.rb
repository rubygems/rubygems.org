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
