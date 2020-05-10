require "test_helper"
require "capybara/minitest"

class TransitiveDependenciesTest < SystemTest
  setup { headless_chrome_driver }

  test "loading transitive dependencies using ajax" do
    @version_one = create(:version)
    @rubygem_one = @version_one.rubygem

    @rubygem_two = create(:rubygem)
    @version_two = ["1.0.2", "2.4.3", "4.5.6"].map do |ver_number|
      FactoryBot.create(:version, number: ver_number, rubygem: @rubygem_two)
    end
    @version_three = create(:version)
    @rubygem_three = @version_three.rubygem
    @version_four = create(:version)
    @rubygem_four = @version_four.rubygem

    @version_one.dependencies << create(:dependency,
      requirements: ">=0",
      scope: :runtime,
      version: @version_one,
      rubygem: @rubygem_two)
    @version_two.each do |ver2|
      ver2.dependencies << create(:dependency,
        version: ver2,
        rubygem: @rubygem_three)

      ver2.dependencies << create(:dependency,
        version: ver2,
        rubygem: @rubygem_four)
    end

    visit rubygem_version_dependencies_path(rubygem_id: @rubygem_one.name, version_id: @version_one.number)
    assert page.has_content?(@rubygem_one.name)
    assert page.has_content?(@version_one.number)
    assert page.has_content?(@rubygem_two.name)
    assert page.has_content?(@version_two[2].number)
    find("span.deps_expanded-link").click
    assert page.has_content?(@rubygem_three.name)
    assert page.has_content?(@version_three.number)
    assert page.has_content?(@rubygem_four.name)
    assert page.has_content?(@version_four.number)
  end

  # Reset sessions and driver between tests
  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
