require "application_system_test_case"

class StatsTest < ApplicationSystemTestCase
  setup do
    @rubygem = create(:rubygem, number: "0.0.1", downloads: 100)
  end

  test "downloads animation bar" do
    visit stats_path
    assert page.find(:css, ".stats__graph__gem__meter")
    assert page.has_content?(@rubygem.downloads)
  end
end
