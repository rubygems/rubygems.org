require "test_helper"

class YankTest < SystemTest
  setup do
    @user = create(:user, password: PasswordHelpers::SECURE_TEST_PASSWORD)
    @rubygem = create(:rubygem, name: "sandworm")
    create(:ownership, user: @user, rubygem: @rubygem)

    @user_api_key = "12345"
    create(:api_key, user: @user, key: @user_api_key, yank_rubygem: true)
    Dir.chdir(Dir.mktmpdir)

    visit sign_in_path
    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"
  end

  test "view yanked gem" do
    create(:version, rubygem: @rubygem, number: "1.1.1")
    create(:version, rubygem: @rubygem, number: "2.2.2")

    page.driver.browser.header("Authorization", @user_api_key)
    page.driver.delete yank_api_v1_rubygems_path(gem_name: @rubygem.name, version: "2.2.2")

    visit dashboard_path
    assert page.has_content? "sandworm"

    click_link "sandworm"
    assert page.has_content?("1.1.1")
    refute page.has_content?("2.2.2")

    within ".versions" do
      click_link "Show all versions (2 total)"
    end
    click_link "2.2.2"
    assert page.has_content? "This version has been yanked"
    assert page.has_css? 'meta[name="robots"][content="noindex"]', visible: false

    assert page.has_content?("Yanked by")

    css = %(div.gem__users a[alt=#{@user.handle}])
    assert page.has_css?(css, count: 3)
  end

  test "yanked gem entirely then someone else pushes a new version" do
    create(:version, rubygem: @rubygem, number: "0.0.0")

    visit rubygem_path(@rubygem)
    assert page.has_content? "sandworm"
    assert page.has_content? "0.0.0"

    page.driver.browser.header("Authorization", @user_api_key)
    page.driver.delete yank_api_v1_rubygems_path(gem_name: @rubygem.name, version: "0.0.0")

    visit rubygem_path(@rubygem)
    assert page.has_content? "sandworm"
    assert page.has_content? "This gem is not currently hosted on RubyGems.org"

    other_user_key = "12323"
    other_api_key = create(:api_key, key: other_user_key, push_rubygem: true)

    build_gem "sandworm", "1.0.0"
    page.driver.browser.header("Authorization", other_user_key)
    page.driver.post api_v1_rubygems_path, File.read("sandworm-1.0.0.gem"),
      "CONTENT_TYPE" => "application/octet-stream"

    visit rubygem_path(@rubygem)
    assert page.has_content? "sandworm"
    assert page.has_content? "1.0.0"
    assert page.has_selector?("a[alt='#{other_api_key.user.handle}']")
    refute page.has_content?("0.0.0")
    refute page.has_selector?("a[alt='#{@user.handle}']")
  end

  teardown do
    RubygemFs.mock!
    Dir.chdir(Rails.root)
  end
end
