# frozen_string_literal: true

require "application_system_test_case"

class GemFilterTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    { "aws-sdk-zeta" => 30, "aws-sdk-alpha" => 10, "aws-tools" => 20, "other-sdk" => 40 }.each do |name, downloads|
      create(:version, rubygem: create(:rubygem, name:, downloads:, owners: [@user], organization: @organization))
    end
  end

  test "visitors filter gem names, sort matching gems and reset on profiles and organization pages" do
    [profile_path(@user.handle), organization_path(@organization), organization_gems_path(@organization)].each do |path|
      visit "#{path}?sort=downloads"

      assert_equal %w[other-sdk aws-sdk-zeta aws-tools aws-sdk-alpha], all("h4").map(&:text)
      fill_in "Filter by gem name", with: "  SDK   AwS  "

      assert_selector "h4", count: 2
      assert_equal %w[aws-sdk-zeta aws-sdk-alpha], all("h4").map(&:text)
      assert_selector "[role='status']", text: "Matching gems: 2 of 4"

      click_button "Sort: Number of downloads"
      click_link "Alphabetical"

      assert_selector "button", text: "Sort: Alphabetical"
      assert_selector "h4", count: 2
      assert_equal %w[aws-sdk-alpha aws-sdk-zeta], all("h4").map(&:text)

      # This word appears in every gem's description, but not in its name.
      fill_in "Filter by gem name", with: "awesome"

      assert_no_selector "h4"
      assert_selector "[role='status']", text: "Matching gems: 0 of 4"
      assert_text "No gems match your filter."
      find("button[aria-label='Clear filter']").click

      assert_selector "h4", count: 4
      assert_equal %w[aws-sdk-alpha aws-sdk-zeta aws-tools other-sdk], all("h4").map(&:text)
      assert_field "Filter by gem name", with: ""
      assert_selector "input[aria-label='Filter by gem name']:focus"
      assert_no_text "No gems match your filter."

      fill_in "Filter by gem name", with: "   "

      assert_selector "h4", count: 4
      assert_selector "[role='status']", text: "4 gems"

      fill_in "Filter by gem name", with: "other"
      find_field("Filter by gem name").send_keys(:escape)

      assert_selector "h4", count: 4
      assert_field "Filter by gem name", with: ""
    end
  end

  test "filter remains usable with the native sort fallback" do
    page.driver.with_playwright_page do |pw_page|
      pw_page.add_init_script(script: "delete HTMLElement.prototype.showPopover")
    end
    visit profile_path(@user.handle, sort: "downloads")
    fill_in "Filter by gem name", with: "AWS sdk"
    select "Alphabetical", from: "Sort gems by"
    click_button "Apply sort"

    assert_selector "h4", count: 2
    assert_equal %w[aws-sdk-alpha aws-sdk-zeta], all("h4").map(&:text)
    assert_field "Filter by gem name", with: "AWS sdk"
  end

  test "filter and sort have matching heights and fit desktop and narrow screens" do
    devices = %i[desktop mobile]
    [profile_path(@user.handle), organization_path(@organization), organization_gems_path(@organization)].each do |path|
      visit path
      devices.each do |device|
        use_device_profile(device)
        input = find_field("Filter by gem name")
        sort = find("button[aria-haspopup='menu']")
        input_box = input.evaluate_script("this.getBoundingClientRect().toJSON()")
        sort_box = sort.evaluate_script("this.getBoundingClientRect().toJSON()")

        assert_equal 38, input_box.fetch("height")
        assert_equal 38, sort_box.fetch("height")
        if device == :desktop
          assert_equal input_box.fetch("top"), sort_box.fetch("top")
          assert_equal input_box.fetch("bottom"), sort_box.fetch("bottom")
        else
          assert_operator sort_box.fetch("top"), :>=, input_box.fetch("bottom")
          assert_operator input_box.fetch("right"), :<=, 393
          assert_operator sort_box.fetch("right"), :<=, 393
        end
      end
    end
  end
end
