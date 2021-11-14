require "test_helper"

class PageParamsTest < SystemTest
  include ESHelper

  test "stats with page param more than 10" do
    visit stats_path(page: "11")
    assert redirect_to(stats_path(page: "1"))
    assert page.has_content? "Stats"
    assert page.has_content? "Page number is out of range. Redirected to default page."
  end

  test "search with page more than 100" do
    visit search_path(page: "102")
    assert redirect_to(search_path(page: "1"))
    assert page.has_content? "search"
    assert page.has_content? "Page number is out of range. Redirected to default page."
  end

  test "news with page more than 10" do
    visit news_path(page: "12")
    assert redirect_to(news_path(page: "1"))
    assert page.has_content? "New Releases — All Gems"
    assert page.has_content? "Page number is out of range. Redirected to default page."
  end

  test "popular news with page more than 10" do
    visit popular_news_path(page: "12")
    assert redirect_to(popular_news_path(page: "1"))
    assert page.has_content? "New Releases — Popular Gems"
    assert page.has_content? "Page number is out of range. Redirected to default page."
  end

  test "api search with page smaller than 1" do
    create(:rubygem, name: "some", number: "1.0.0")
    import_and_refresh
    visit api_v1_search_path(page: "0", query: "some", format: :json)
    assert redirect_to(api_v1_search_path(page: "1", query: "some", format: :json))
    refute_empty JSON.parse(page.body)
  end

  test "api search with page is not a numer" do
    create(:rubygem, name: "some", number: "1.0.0")
    import_and_refresh
    visit api_v1_search_path(page: "foo", query: "some", format: :json)
    assert redirect_to(api_v1_search_path(page: "1", query: "some", format: :json))
    refute_empty JSON.parse(page.body)
  end

  test "api search with page that can't be converted to a number" do
    create(:rubygem, name: "some", number: "1.0.0")
    import_and_refresh
    visit api_v1_search_path(page: { "$acunetix" => "1" }, query: "some", format: :json)
    assert redirect_to(api_v1_search_path(page: "1", query: "some", format: :json))
    refute_empty JSON.parse(page.body)
  end
end
