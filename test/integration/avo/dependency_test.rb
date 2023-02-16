require "test_helper"

class Avo::RubygemsTest < ActionDispatch::IntegrationTest
  include AdminHelpers
  include Capybara::Minitest::Assertions

  test "getting dependencies as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_dependencies_path
    assert_response :found

    version = create(:version) do |v|
      v.dependencies = [
        build(:dependency, :runtime),
        build(:dependency, :development),
        build(:dependency, :unresolved)
      ]
    end
    runtime, development, unresolved = version.dependencies

    get avo.resources_dependencies_path
    assert_response :found

    get avo.resources_dependency_path(runtime)
    assert_response :success
    assert_text version.full_name
    assert_text runtime.rubygem.name
    assert_text "= 1.0.0"
    assert_text "runtime"

    get avo.resources_dependency_path(development)
    assert_response :success
    assert_text version.full_name
    assert_text development.rubygem.name
    assert_text "= 1.0.0"
    assert_text "development"

    get avo.resources_dependency_path(unresolved)
    assert_response :success
    assert_text version.full_name
    assert_text "unresolved-gem-nothere"
    assert_text "= 1.0.0"
    assert_text "runtime"
  end
end
