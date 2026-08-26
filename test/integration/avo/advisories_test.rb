# frozen_string_literal: true

require "test_helper"

class Avo::AdvisoriesTest < ActionDispatch::IntegrationTest
  include AdminHelpers

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
end
