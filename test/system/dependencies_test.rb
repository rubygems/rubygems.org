# frozen_string_literal: true

require "application_system_test_case"

class DependenciesTest < ApplicationSystemTestCase
  test "viewing the dependencies table" do
    version_one = create(:version)
    rubygem_one = version_one.rubygem

    rubygem_two = create(:rubygem)
    ["1.0.2", "2.4.3", "4.5.6"].map do |ver_number|
      FactoryBot.create(:version, number: ver_number, rubygem: rubygem_two)
    end

    create(:dependency, requirements: "<= 4.0.0", scope: :runtime, version: version_one, rubygem: rubygem_two)
    create(:dependency, requirements: ">= 0", scope: :development, version: version_one, rubygem: create(:rubygem, number: "1.0.0"))

    visit rubygem_version_dependencies_path(rubygem_id: rubygem_one.slug, version_id: version_one.number)

    assert_text(rubygem_one.name)
    assert_text(version_one.number)
    assert_text("1 Runtime Dependency")
    assert_text("1 Development Dependency")
    assert_text(rubygem_two.name)
    # the highest version matching the requirements is resolved and linked
    assert_link(href: rubygem_version_path(rubygem_two.slug, "2.4.3"))
    assert_text("<= 4.0.0")
  end

  test "resolved dependency versions match the gem platform" do
    version = create(:version, platform: "jruby")

    dep_version = create(:version, number: "1.0.0", platform: "jruby")
    create(:dependency, rubygem: dep_version.rubygem, version: version)

    visit rubygem_path(version.rubygem.slug)
    click_on "Dependencies"

    assert_text(dep_version.rubygem.name)
    assert_text(dep_version.slug)
  end

  test "viewing reverse dependencies" do
    version = create(:version)
    rubygem = version.rubygem

    dependent_version = create(:version, number: "3.1.0")
    create(:dependency, requirements: ">= 0", scope: :runtime, version: dependent_version, rubygem: rubygem)
    create(:dependency, requirements: ">= 0", scope: :runtime, version: version, rubygem: create(:rubygem, number: "1.0.0"))

    visit rubygem_version_dependencies_path(rubygem_id: rubygem.slug, version_id: version.number)

    assert_text("Reverse Dependencies")
    assert_link(dependent_version.rubygem.name, href: rubygem_path(dependent_version.rubygem.slug))
    click_on "See all reverse dependencies"

    assert_current_path rubygem_reverse_dependencies_path(rubygem.slug)
  end
end
