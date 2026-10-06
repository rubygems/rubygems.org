# frozen_string_literal: true

require "test_helper"

class Avo::RubygemsTest < ActionDispatch::IntegrationTest
  include AdminHelpers
  include ActiveJob::TestHelper

  def post_bulk_yank(rubygems)
    post "/admin/resources/rubygems/actions",
      params: {
        action_id: "Avo::Actions::YankRubygem",
        resource_view: "index",
        fields: {
          avo_resource_ids: rubygems.map(&:to_param).join(","),
          comment: "Yanking gems from a malicious campaign",
          version: Avo::Actions::YankRubygem::OPTION_ALL
        }
      },
      as: :turbo_stream
  end

  test "bulk yanking rubygems as a rubygems.org operator" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    create(:user, email: "security@rubygems.org")
    rubygems = create_list(:rubygem, 2)
    versions = rubygems.flat_map { |rubygem| create_list(:version, 2, rubygem:) }

    post_bulk_yank(rubygems)

    assert_response :success
    versions.each { |version| refute_nil version.reload.yanked_at }
    rubygems.each { |rubygem| assert_equal "Yank Rubygem", rubygem.audits.sole.action }
  end

  test "not bulk yanking rubygems as an operator outside the rubygems.org team" do
    admin = create(:admin_github_user, :is_admin)
    info_data = admin.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    admin.update!(info_data:)
    admin_sign_in_as admin
    create(:user, email: "security@rubygems.org")
    rubygems = create_list(:rubygem, 2)
    versions = rubygems.flat_map { |rubygem| create_list(:version, 2, rubygem:) }
    version_attributes = versions.map { it.reload.attributes }

    assert_no_enqueued_jobs do
      post_bulk_yank(rubygems)
    end

    assert_redirected_to avo.root_path
    assert_equal(version_attributes, versions.map { it.reload.attributes })
    assert_empty Deletion.all
    assert_empty Audit.all
  end

  test "not bulk yanking more rubygems than fit on one index page" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    create(:user, email: "security@rubygems.org")
    rubygems = create_list(:rubygem, Avo.configuration.per_page_steps.max + 1)
    version = create(:version, rubygem: rubygems.first)

    assert_no_enqueued_jobs do
      post_bulk_yank(rubygems)
    end

    assert_response :success
    assert_equal "Select at most 72 gems to yank at once", flash[:error][:body]
    assert_nil version.reload.yanked_at
    assert_empty Deletion.all
    assert_empty Audit.all
  end

  test "getting rubygems as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_rubygems_path

    assert_response :success

    rubygem = create(:rubygem)

    get avo.resources_rubygems_path

    assert_response :success
    assert page.has_content? rubygem.name

    get avo.resources_rubygem_path(rubygem)

    assert_response :success
    assert page.has_content? rubygem.name
  end

  test "searching rubygems by name prefix" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    8.times { |index| create(:rubygem, name: "fuzzy-#{index}-search_prefix") }
    exact_match = create(:rubygem, name: "search_prefix")
    longer_match = create(:rubygem, name: "search_prefix-extension")
    create(:rubygem, name: "searchXprefix")

    get avo.avo_api_path(resource_name: "rubygems"), params: { q: "search_prefix" }

    assert_response :success
    assert_equal \
      [exact_match.to_param, longer_match.to_param].sort,
      response.parsed_body.dig("rubygems", "results").pluck("_id").sort
  end
end
