# frozen_string_literal: true

require "test_helper"

class Avo::TemporaryPushGrantsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  setup do
    @grant = create(:temporary_push_grant, version: "4.2.0")
    create(:temporary_push_grant_artifact, temporary_push_grant: @grant, platform: "x86_64-linux")
  end

  test "operators see grants and their lifecycle actions" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_temporary_push_grants_path

    assert_response :success
    page.assert_text "4.2.0"

    get avo.resources_temporary_push_grant_path(@grant)

    assert_response :success
    page.assert_text "draft"

    %w[Approve Activate Suspend Resume Revoke].each do |verb|
      assert_select "a[data-action-name='#{verb} Temporary Push Grant']", count: 1
    end
  end

  test "operators create a grant with an audit" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    attributes = attributes_for(:temporary_push_grant).merge(
      rubygem_id: create(:rubygem).id, grantee_id: create(:user).id, comment: "Opening grant for request #12"
    )

    assert_difference [-> { TemporaryPushGrant.count }, -> { Audit.count }], 1 do
      post avo.resources_temporary_push_grants_path, params: { temporary_push_grant: attributes }
    end
  end

  test "operators outside the rubygems.org team cannot see or create grants" do
    requires_avo_pro
    admin = create(:admin_github_user, :is_admin)
    info_data = admin.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    admin.update!(info_data:)
    admin_sign_in_as admin

    get avo.resources_temporary_push_grant_path(@grant)

    assert_redirected_to avo.root_path

    assert_no_difference [-> { TemporaryPushGrant.count }, -> { Audit.count }] do
      post avo.resources_temporary_push_grants_path, params: { temporary_push_grant: { version: "9.9.9", comment: "Not allowed here" } }
    end
  end
end
