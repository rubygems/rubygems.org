require "test_helper"
require "capybara/minitest"

class TransitiveDependenciesTest < SystemTest
  setup { headless_chrome_driver }

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

    visit rubygem_version_dependencies_path(rubygem_id: rubygem_one.name, version_id: version_one.number)
    assert_text(rubygem_one.name)
    assert_text(version_one.number)
    assert_text(rubygem_two.name)
    assert_text(version_two[2].number)
    find("span.deps_expanded-link").click
    assert_text(version_four.rubygem.name)
    assert_text(version_three.number)
    assert_text(version_four.rubygem.name)
    assert_text(version_four.number)
  end

  test "loading transitive dependencies for jruby platform" do
    version = create(:version, platform: "jruby")

    dep_version = create(:version, number: "1.0.0", platform: "jruby")
    create(:dependency, rubygem: dep_version.rubygem, version: version)

    dep_dep_version = create(:version, platform: "jruby")
    create(:dependency, requirements: ">=0", scope: :runtime, rubygem: dep_dep_version.rubygem, version: dep_version)

    visit rubygem_path(version.rubygem)
    click_on "Show all transitive dependencies"
    assert_text(dep_version.rubygem.name)
    assert_text(dep_version.slug)
    find("span.deps_expanded-link").click
    assert_text(dep_dep_version.rubygem.name)
    assert_text(dep_dep_version.slug)
  end

  # Reset sessions and driver between tests
  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
