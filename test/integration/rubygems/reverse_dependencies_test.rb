# frozen_string_literal: true

require "test_helper"

class Rubygems::ReverseDependenciesTest < ActionDispatch::IntegrationTest
  setup do
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
  end

  test "anonymous reverse dependencies page sets public cache headers" do
    get rubygem_reverse_dependencies_path(@rubygem.slug)

    assert_response :success
    assert_nil response.headers["Set-Cookie"]
    assert_includes response.headers["Cache-Control"], "public"
    assert_includes response.headers["Surrogate-Control"], "max-age=60"
    assert_equal "gem/sandworm/reverse_dependencies", response.headers["Surrogate-Key"]
  end
end
