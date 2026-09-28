# frozen_string_literal: true

require "test_helper"

class Avo::AdvisoriesTest < ActionDispatch::IntegrationTest
  include AdminHelpers
  include ActiveJob::TestHelper

  test "getting advisories as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_advisories_path

    assert_response :success

    advisory = create(:advisory)

    get avo.resources_advisories_path

    assert_response :success
    assert page.has_content? advisory.identifier

    get avo.resources_advisory_path(advisory)

    assert_response :success
    assert page.has_content? advisory.identifier
    assert page.has_content? advisory.rubygem_name
  end

  test "syncing advisories as admin" do
    admin = create(:admin_github_user, :is_admin)
    admin_sign_in_as admin

    Advisory::OSV::Fetcher.any_instance.expects(:fetch).never

    post "/admin/resources/advisories/actions",
      params: {
        action_id: "Avo::Actions::SyncAdvisories",
        resource_view: "index",
        fields: {
          comment: "Warming the advisories table before enabling the public flag",
          source: "Advisory::OSV"
        }
      },
      as: :turbo_stream

    assert_response :success
    assert_enqueued_jobs 1, only: SyncAdvisoriesJob
    assert_enqueued_with(job: SyncAdvisoriesJob, args: [source: "Advisory::OSV", force: true])

    audit = Audit.where(action: "Sync Advisories").sole

    assert_equal admin, audit.admin_github_user
    assert_equal admin, audit.auditable
  end

  test "not syncing advisories as an operator outside the rubygems.org team" do
    admin = create(:admin_github_user, :is_admin)
    info_data = admin.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    admin.update!(info_data:)
    admin_sign_in_as admin
    advisory = create(:advisory)
    advisory_attributes = advisory.attributes
    Advisory::OSV::Fetcher.any_instance.expects(:fetch).never

    assert_no_enqueued_jobs only: SyncAdvisoriesJob do
      post "/admin/resources/advisories/actions",
        params: {
          action_id: "Avo::Actions::SyncAdvisories",
          resource_view: "index",
          fields: {
            comment: "Warming the advisories table before enabling the public flag",
            source: "Advisory::OSV"
          }
        },
        as: :turbo_stream
    end

    assert_redirected_to avo.root_path
    assert_empty Audit.where(action: "Sync Advisories")
    assert_equal advisory_attributes, Advisory.find(advisory.id).attributes
  end
end
