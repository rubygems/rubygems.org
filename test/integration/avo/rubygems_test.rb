# frozen_string_literal: true

require "test_helper"

class Avo::RubygemsTest < ActionDispatch::IntegrationTest
  include AdminHelpers

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
