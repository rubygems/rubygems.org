require "application_system_test_case"

class TransitiveDependenciesTest < ApplicationSystemTestCase
  test "loading transitive dependencies using ajax" do
    version_one = create(:version)
    rubygem_one = version_one.rubygem

    rubygem_two = create(:rubygem)
    version_two = ["1.0.2", "2.4.3", "4.5.6"].map do |ver_number|
      FactoryBot.create(:version, number: ver_number, rubygem: rubygem_two)
    end
    version_three = create(:version)
    version_four = create(:version)

    create(:dependency, requirements: ">=0", scope: :runtime, version: version_one, rubygem: rubygem_two)

    version_two.each do |ver2|
      create(:dependency, requirements: ">=0", scope: :runtime, version: ver2, rubygem: version_three.rubygem)
      create(:dependency, requirements: ">=0", scope: :runtime, version: ver2, rubygem: version_four.rubygem)
    end

    visit rubygem_version_dependencies_path(rubygem_id: rubygem_one.slug, version_id: version_one.number)

    assert page.has_content?(rubygem_one.name)
    assert page.has_content?(version_one.number)
    assert page.has_content?(rubygem_two.name)
    page.assert_text(version_two[2].number)
    find("span.deps_expanded-link").click

    assert page.has_content?(version_four.rubygem.name)
    assert page.has_content?(version_three.number)
    assert page.has_content?(version_four.rubygem.name)
    assert page.has_content?(version_four.number)
  end

  test "loading transitive dependencies for jruby platform" do
    version = create(:version, platform: "jruby")

    dep_version = create(:version, number: "1.0.0", platform: "jruby")
    create(:dependency, rubygem: dep_version.rubygem, version: version)

    dep_dep_version = create(:version, platform: "jruby")
    create(:dependency, requirements: ">=0", scope: :runtime, rubygem: dep_dep_version.rubygem, version: dep_version)

    visit rubygem_path(version.rubygem.slug)
    click_on "Show all transitive dependencies"

    assert page.has_content?(dep_version.rubygem.name)
    assert page.has_content?(dep_version.slug)
    find("span.deps_expanded-link").click

    assert page.has_content?(dep_dep_version.rubygem.name)
    assert page.has_content?(dep_dep_version.slug)
  end
end
