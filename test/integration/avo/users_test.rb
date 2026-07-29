# frozen_string_literal: true

require "test_helper"

class Avo::UsersTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting users as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_users_path

    assert_response :success

    user = create(:user)

    get avo.resources_users_path

    assert_response :success
    assert page.has_content? user.name

    get avo.resources_user_path(user)

    assert_response :success
    assert page.has_content? user.name
  end

  test "showing the delete action to rubygems.org operators on the user page" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)

    get avo.resources_user_path(user)

    assert_response :success
    assert page.has_content? "Delete User"
  end

  test "disabling the delete action when the user is the sole owner of an old gem version" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    create(:version, rubygem:, created_at: 31.days.ago)

    get avo.resources_user_path(user)

    assert_response :success
    assert page.has_content?(
      "Delete User — Blocked because this user is the sole owner of gem versions published more than 30 days ago."
    )
    assert_select "a[data-action-name^='Delete User'][data-disabled='true']", count: 1
  end

  test "enabling the delete action when an old gem version has another owner" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)
    rubygem = create(:rubygem, owners: [user, create(:user)])
    create(:version, rubygem:, created_at: 31.days.ago)

    get avo.resources_user_path(user)

    assert_response :success
    assert_select "a[data-action-name='Delete User'][data-disabled='false']", count: 1
    refute page.has_content? Avo::Actions::DeleteUser.blocked_reason
  end

  test "enabling the delete action when the user's old gem version is already yanked" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    user = create(:user)
    rubygem = create(:rubygem, owners: [user])
    create(:version, rubygem:, created_at: 31.days.ago, indexed: false)
    create(:version, rubygem:)

    get avo.resources_user_path(user)

    assert_response :success
    assert_select "a[data-action-name='Delete User'][data-disabled='false']", count: 1
    refute page.has_content? Avo::Actions::DeleteUser.blocked_reason
  end

  test "not showing the delete action on the users index" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_users_path

    assert_response :success
    refute page.has_content? "Delete User"
  end

  test "not showing the delete action to operators outside the rubygems.org team" do
    admin = create(:admin_github_user, :is_admin)
    info_data = admin.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    admin.update!(info_data:)
    admin_sign_in_as admin

    get avo.resources_user_path(create(:user))

    assert_response :success
    refute page.has_content? "Delete User"
  end
end
