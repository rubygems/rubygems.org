require "application_system_test_case"

class PageParamsTest < ApplicationSystemTestCase
  include SearchKickHelper

  test "stats with page param more than 10" do
    visit stats_path(page: "11")

    assert redirect_to(stats_path(page: "1"))
    assert_text "Stats"
    assert_text "Page number is out of range. Redirected to default page."
  end

  test "search with page more than 100" do
    visit search_path(page: "102")

    assert redirect_to(search_path(page: "1"))
    assert_text "search"
    assert_text "Page number is out of range. Redirected to default page."
  end

  test "news with page more than 10" do
    visit news_path(page: "12")

    assert redirect_to(news_path(page: "1"))
    assert_text "New Releases — All Gems"
    assert_text "Page number is out of range. Redirected to default page."
  end

  test "popular news with page more than 10" do
    visit popular_news_path(page: "12")

    assert redirect_to(popular_news_path(page: "1"))
    assert_text "New Releases — Popular Gems"
    assert_text "Page number is out of range. Redirected to default page."
  end
end
