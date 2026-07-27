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
