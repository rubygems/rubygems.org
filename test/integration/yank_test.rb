require 'test_helper'

class YankTest < SystemTest
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm")
    create(:ownership, user: @user, rubygem: @rubygem)
    Dir.chdir(Rails.root.join("tmp"))
  end

  test "view yanked gem" do
    create(:version, rubygem: @rubygem, number: "1.1.1")
    create(:version, rubygem: @rubygem, number: "2.2.2")

    page.driver.browser.header("Authorization", @user.api_key)
    page.driver.delete yank_api_v1_rubygems_path(gem_name: @rubygem.name, version: "2.2.2")

    visit dashboard_path
    assert page.has_content? "sandworm"

    click_link "sandworm"
    assert page.has_content?("1.1.1")
    assert ! page.has_content?("2.2.2")

    within ".versions" do
      click_link "Show all versions (2 total)"
    end
    click_link "2.2.2"
    assert page.has_content? "This gem has been yanked"
    assert page.has_css? 'meta[name="robots"][content="noindex"]', visible: false
  end

  test "yanked gem entirely then someone else pushes a new version" do
    create(:version, rubygem: @rubygem, number: "0.0.0")

    visit rubygem_path(@rubygem)
    assert page.has_content? "sandworm"
    assert page.has_content? "0.0.0"

    page.driver.browser.header("Authorization", @user.api_key)
    page.driver.delete yank_api_v1_rubygems_path(gem_name: @rubygem.name, version: "0.0.0")

    visit rubygem_path(@rubygem)
    assert page.has_content? "sandworm"
    assert page.has_content? "This gem has been yanked"

    other_user = create(:user)

    build_gem "sandworm", "1.0.0"
    page.driver.browser.header("Authorization", other_user.api_key)
    page.driver.post api_v1_rubygems_path, File.read("sandworm-1.0.0.gem"), {"CONTENT_TYPE" => "application/octet-stream"}

    visit rubygem_path(@rubygem)
    assert page.has_content? "sandworm"
    assert page.has_content? "1.0.0"
    assert page.has_content? other_user.handle
    assert ! page.has_content?("0.0.0")
    assert ! page.has_content?(@user.handle)
  end

  test "undo a yank is not supported" do
    create(:version, rubygem: @rubygem, number: "1.0.0", indexed: true)
    create(:version, rubygem: @rubygem, number: "0.0.0", indexed: false)

    page.driver.browser.header("Authorization", @user.api_key)
    page.driver.put unyank_api_v1_rubygems_path(gem_name: @rubygem.name, version: "0.0.0")

    visit dashboard_path
    assert page.has_content? "sandworm"

    click_link "sandworm"
    assert page.has_content?("1.0.0")
    assert ! page.has_content?("0.0.0")
  end

  teardown do
    Dir.chdir(Rails.root)
  end
end
