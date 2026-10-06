# frozen_string_literal: true

require "test_helper"

class GemSortPreferenceTest < ActionDispatch::IntegrationTest
  include SearchKickHelper

  # Each order is distinct: downloads b,c,a; name a,b,c; recent a,c,b.
  setup do
    @user = create(:user)
    @organization = create(:organization, owners: [@user])
    { "sortgem-b" => [30, 3.days.ago], "sortgem-a" => [10, 1.day.ago], "sortgem-c" => [20, 2.days.ago] }.each do |name, (downloads, published)|
      rubygem = create(:rubygem, name:, downloads:, owners: [@user], organization: @organization)
      create(:version, rubygem:, created_at: published)
      rubygem.update_column(:updated_at, published)
      rubygem.reindex(refresh: true)
    end
  end

  test "profile defaults to downloads and offers the three orders" do
    get profile_path(@user.handle)

    assert_equal %w[sortgem-b sortgem-c sortgem-a], listed_gems
    assert_nil cookies[:gem_sort]
    assert_select "button[aria-haspopup='menu'][aria-expanded='false']", text: "Sort: Number of downloads"
    assert_select "[role='menu'][aria-label='Sort gems by'] [role='menuitemradio']" do |items|
      assert_equal(["Most recently published", "Number of downloads", "Alphabetical"], items.map { it.text.strip })
      assert_equal(%w[false true false], items.pluck("aria-checked"))
      assert_equal %w[recent downloads name].map { "#{profile_path(@user.handle)}?sort=#{it}" }, items.pluck("href")
    end
  end

  test "choosing an order remembers it in a permanent cookie shared by profile and organization pages" do
    get profile_path(@user.handle, sort: "name")

    assert_equal %w[sortgem-a sortgem-b sortgem-c], listed_gems
    set_cookie = response.headers["Set-Cookie"].lines.grep(/\Agem_sort=/).first

    assert_match(/expires=[^;]*#{20.years.from_now.year}/i, set_cookie)
    assert_match(/httponly/i, set_cookie)
    assert_match(/samesite=lax/i, set_cookie)

    get profile_path(@user.handle)

    assert_equal %w[sortgem-a sortgem-b sortgem-c], listed_gems
    assert_select "[role='menuitemradio'][aria-checked='true']", text: "Alphabetical"

    get organization_path(@organization)

    assert_equal %w[sortgem-a sortgem-b sortgem-c], listed_gems

    get organization_gems_path(@organization, sort: "recent")

    assert_equal %w[sortgem-a sortgem-c sortgem-b], listed_gems
    assert_equal "recent", cookies[:gem_sort]
  end

  test "an unknown order is ignored and keeps the remembered one" do
    get profile_path(@user.handle, sort: "name")
    get profile_path(@user.handle, sort: "downloads); DROP TABLE rubygems; --")

    assert_response :success
    assert_equal %w[sortgem-a sortgem-b sortgem-c], listed_gems
    assert_equal "name", cookies[:gem_sort]
  end

  test "search defaults to best match, and remembering best match leaves other pages on downloads" do
    get search_path(query: "sortgem", page: 1)

    assert_select "button[aria-haspopup='menu']", text: "Sort: Best match"
    assert_select "[role='menuitemradio']" do |items|
      assert_equal(["Best match", "Most recently published", "Number of downloads", "Alphabetical"], items.map { it.text.strip })
      # Changing the order keeps the query and goes back to the first page.
      assert_equal "#{search_path}?query=sortgem&sort=name", items.last["href"]
    end

    get search_path(query: "sortgem", sort: "relevance")

    assert_equal "relevance", cookies[:gem_sort]

    get profile_path(@user.handle)

    assert_equal %w[sortgem-b sortgem-c sortgem-a], listed_gems
  end

  test "search uses the remembered order" do
    get profile_path(@user.handle, sort: "recent")
    get search_path(query: "sortgem")

    assert_equal(%w[sortgem-a sortgem-c sortgem-b], css_select("[data-testid='rubygem-name']").map { it.text.strip })
    assert_select "[role='menuitemradio'][aria-checked='true']", text: "Most recently published"
  end

  private

  def listed_gems
    css_select("h4").map { it.text.strip }
  end
end
