# frozen_string_literal: true

require "test_helper"
require "helpers/rate_limit_helpers"

class Avo::UsersTest < ActionDispatch::IntegrationTest
  include AdminHelpers
  include RateLimitHelpers

  setup do
    # Other parallel workers clear the shared Memcached store between tests.
    @original_rack_attack_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rack::Attack.cache.store = @original_rack_attack_store
  end

  test "getting users as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user, created_at: Time.zone.local(1997, 4, 15, 12, 30))

    get avo.resources_users_path

    assert_response :success
    assert page.has_content? user.name
    refute page.has_content? "Created at"

    get avo.resources_user_path(user)

    assert_response :success
    assert page.has_content? user.name
    assert page.has_content? "Created at"
    assert page.has_content? user.created_at.utc.iso8601
  end

  test "searching users by blocked email" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    blocked_user = create(:user, :blocked, blocked_email: "blocked_user@rubygems-test.org")
    create(:user, email: "blockedXuser@rubygems-test.org")

    get avo.avo_api_path(resource_name: "users"), params: { q: "blocked_user@rubygems-test" }

    assert_response :success
    assert_equal [blocked_user.to_param], response.parsed_body.dig("users", "results").pluck("_id")
  end

  test "showing the delete action to rubygems.org operators on the user page" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)

    get avo.resources_user_path(user)

    assert_response :success
    assert page.has_content? "Delete User"
  end

  test "showing the unblock action for a blocked user" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user, :blocked)

    get avo.resources_user_path(user)

    assert_response :success
    assert page.has_content? "Unblock User"
  end

  test "resetting a user's gem push throttling without resetting other accounts or IP limits" do
    freeze_time do
      admin = create(:admin_github_user, :is_admin)
      admin_sign_in_as admin
      user = create(:user)
      other_user = create(:user)
      create(:api_key, owner: user, key: "reset-push-key", scopes: %i[push_rubygem])
      create(:api_key, owner: other_user, key: "other-push-key", scopes: %i[push_rubygem])
      [user, other_user].each { |account| exhaust_account_push_throttles(account) }
      update_limit_for("api/push/ip:1.2.3.5", 400, 3600)

      post_test_gem("reset-push-key")

      assert_response :too_many_requests

      get avo.resources_user_path(user)

      assert_response :success
      assert page.has_content? "Reset Gem Push Throttling"

      get "/admin/resources/users/#{user.to_param}/actions",
        params: { action_id: "Avo::Actions::ResetGemPushThrottling", resource_view: "show" }

      assert_response :success
      assert page.has_content? "IP-based limits will not be reset."
      assert_select "textarea[name='fields[comment]']", count: 1
      assert_select "button", text: "Reset Throttling"

      post_push_throttle_reset(user)

      assert_response :success
      audit = Audit.where(action: "Reset Gem Push Throttling").sole

      assert_equal admin, audit.admin_github_user
      assert_equal user, audit.auditable
      assert_equal "Resetting push throttling at the publisher's request", audit.comment

      post_test_gem("other-push-key")

      assert_response :too_many_requests

      post_test_gem("reset-push-key", ip: "1.2.3.5")

      assert_response :too_many_requests

      assert_difference "Version.count", 1 do
        post_test_gem("reset-push-key")

        assert_response :success
        assert_includes response.body, "Successfully registered gem"
      end
      assert_predicate Version.find_by!(number: "0.0.0"), :indexed?
    end
  end

  test "not resetting push throttling as an operator outside the rubygems.org team" do
    admin = create(:admin_github_user, :is_admin)
    info_data = admin.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    admin.update!(info_data:)
    admin_sign_in_as admin
    [1, 2].each do |level|
      user = create(:user)
      attributes = user.reload.attributes
      create(:api_key, owner: user, key: "denied-push-key-#{level}", scopes: %i[push_rubygem])
      exceed_exponential_api_key_limit_for("api/exp/push/user/#{level}", user.to_gid, level)

      assert_no_difference "Audit.count" do
        assert_no_enqueued_jobs do
          post_push_throttle_reset(user)
        end
      end

      assert_redirected_to avo.root_path
      assert_equal attributes, user.reload.attributes

      assert_no_difference ["Rubygem.count", "Version.count", "Ownership.count"] do
        assert_no_enqueued_jobs do
          post_test_gem("denied-push-key-#{level}")
        end
      end

      assert_response :too_many_requests
    end
  end

  test "requiring an audit comment before resetting push throttling" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    [1, 2].each do |level|
      user = create(:user)
      create(:api_key, owner: user, key: "comment-push-key-#{level}", scopes: %i[push_rubygem])
      exceed_exponential_api_key_limit_for("api/exp/push/user/#{level}", user.to_gid, level)

      assert_no_difference "Audit.count" do
        assert_no_enqueued_jobs do
          post_push_throttle_reset(user, comment: "")
        end
      end

      assert_response :success
      assert_includes response.body, "Must supply a sufficiently detailed comment"

      post_test_gem("comment-push-key-#{level}")

      assert_response :too_many_requests
    end
  end

  test "enabling the delete action when the user is the sole owner of an old gem version" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)
    rubygem = create(:rubygem, name: "admin-delete-blocked-old-gem", owners: [user])
    create(:version, rubygem:, created_at: 31.days.ago)

    get avo.resources_user_path(user)

    assert_response :success
    assert_select "a[data-action-name='Delete User'][data-disabled='false']", count: 1
  end

  test "enabling the delete action when the user is the sole owner of a gem version with too many downloads" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)
    rubygem = create(:rubygem, name: "admin-delete-blocked-popular-gem", owners: [user])
    version = create(:version, rubygem:)
    GemDownload.increment(100_001, rubygem_id: rubygem.id, version_id: version.id)

    get avo.resources_user_path(user)

    assert_response :success
    assert_select "a[data-action-name='Delete User'][data-disabled='false']", count: 1
  end

  test "enabling the delete action when an old gem version has another owner" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)
    rubygem = create(:rubygem, name: "admin-delete-shared-old-gem", owners: [user, create(:user)])
    create(:version, rubygem:, created_at: 31.days.ago)

    get avo.resources_user_path(user)

    assert_response :success
    assert_select "a[data-action-name='Delete User'][data-disabled='false']", count: 1
    refute page.has_content? Avo::Actions::DeleteUser.blocked_reason
  end

  test "enabling the delete action when the user's old gem version is already yanked" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)
    rubygem = create(:rubygem, name: "admin-delete-yanked-old-gem", owners: [user])
    create(:version, rubygem:, created_at: 31.days.ago, indexed: false)
    create(:version, rubygem:)

    get avo.resources_user_path(user)

    assert_response :success
    assert_select "a[data-action-name='Delete User'][data-disabled='false']", count: 1
    refute page.has_content? Avo::Actions::DeleteUser.blocked_reason
  end

  test "showing the delete action to rubygems.org operators on the users index" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_users_path

    assert_response :success
    assert page.has_content? "Delete User"
  end

  test "redirecting operators outside the rubygems.org team" do
    requires_avo_pro
    admin = create(:admin_github_user, :is_admin)
    info_data = admin.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    admin.update!(info_data:)
    admin_sign_in_as admin

    get avo.resources_user_path(create(:user))

    assert_redirected_to avo.root_path
  end

  private

  def exhaust_account_push_throttles(user)
    exceed_exponential_api_key_limit_for("api/exp/push/user/1", user.to_gid, 1)
    exceed_exponential_api_key_limit_for("api/exp/push/user/2", user.to_gid, 2)
  end

  def post_push_throttle_reset(user, comment: "Resetting push throttling at the publisher's request")
    post "/admin/resources/users/#{user.to_param}/actions",
      params: {
        action_id: "Avo::Actions::ResetGemPushThrottling",
        resource_view: "show",
        fields: { avo_resource_ids: user.to_param, comment: }
      },
      as: :turbo_stream
  end

  def post_test_gem(key, ip: "1.2.3.4")
    post "/api/v1/gems",
      params: gem_file("test-0.0.0.gem", &:read),
      headers: { REMOTE_ADDR: ip, HTTP_AUTHORIZATION: key, CONTENT_TYPE: "application/octet-stream" }
  end
end
