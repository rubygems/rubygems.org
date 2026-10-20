# frozen_string_literal: true

require "test_helper"

class ProfilesTest < ActionDispatch::IntegrationTest
  test "visitors can traverse every profile gem in each stable sort order" do
    user = create(:user)
    published = Time.utc(2026, 1, 1)
    # Reverse insertion order catches sorts that rely on IDs to break ties.
    gems = create_list(:rubygem, 65, owners: [user]) do |gem, i| # rubocop:disable FactoryBot/ExcessiveCreateList
      gem.update!(name: format("pagegem-%02d", 65 - i))
      gem.gem_download.update!(count: i < 35 ? 20 : 10)
      create(:version, rubygem: gem, created_at: i < 20 ? published + 1.day : published)
    end
    names = gems.map(&:name).sort
    create(:rubygem, owners: [user], name: "pagegem-unpublished")
    create(:rubygem, name: "pagegem-other-profile", number: "1.0.0")

    orders = {
      "name" => names,
      "downloads" => names.last(35) + names.first(30),
      "recent" => names.last(20) + names.first(45)
    }
    orders.each do |sort, expected|
      visited = []
      1.upto(3) do |number|
        get profile_path(user.handle), params: { sort:, page: number }

        assert_response :success
        listed = css_select("h4").map { it.text.strip }

        assert_equal expected.slice((number - 1) * 30, 30), listed, "#{sort}, page #{number}"
        assert_select "[role='status']", text: "65 gems"
        assert_select "nav[aria-label='Pagination']"
        visited.concat(listed)
      end

      assert_equal expected, visited
      assert_equal 65, visited.uniq.size

      get profile_path(user.handle), params: { sort:, page: 4 }

      assert_response :success
      assert_select "h4", count: 0
      assert_select "nav[aria-label='Pagination'] a", minimum: 1
      refute_match "This user has not pushed any gems yet.", response.body
    end
  end

  test "profile filters search all names before pagination and preserve navigation state" do
    user = create(:user)
    create_list(:rubygem, 30, owners: [user], number: "1.0.0") # rubocop:disable FactoryBot/ExcessiveCreateList
    gems = create_list(:rubygem, 35, owners: [user]) do |gem, i| # rubocop:disable FactoryBot/ExcessiveCreateList
      gem.update!(name: format("aws-sdk-%02d", 35 - i))
      create(:version, rubygem: gem, number: "1.0.0", created_at: Time.utc(2026, 1, 1))
    end
    matches = gems.map(&:name).sort
    create(:rubygem, name: "aws-sdk-outsider", number: "1.0.0")
    create(:rubygem, owners: [user], name: "aws-sdk-unpublished")
    query = "  SDK   AwS  "

    %w[name downloads recent].each do |sort|
      get profile_path(user.handle), params: { sort:, gem_filter: query }

      assert_response :success
      first_page = css_select("h4").map { it.text.strip }

      assert_equal matches.first(30), first_page
      assert_select "[role='status']", text: "Matching gems: 35 of 65"
      assert_select "nav[aria-label='Pagination'] a[rel='next']" do |links|
        get links.first["href"]
      end

      assert_response :success
      last_page = css_select("h4").map { it.text.strip }

      assert_equal matches.last(5), last_page
      assert_equal matches, first_page + last_page
      assert_equal query, request.params["gem_filter"]
      assert_equal sort, request.params["sort"]
      assert_select "[role='menuitemradio']" do |links|
        links.each do |link|
          params = Rack::Utils.parse_query(URI(link["href"]).query)

          assert_equal query, params["gem_filter"]
          assert_nil params["page"]
        end
      end
    end

    ["missing", "aws%", "aws_", "aws\\"].each do |filter|
      get profile_path(user.handle), params: { gem_filter: filter }

      assert_response :success
      assert_select "h4", count: 0
      assert_select "[role='status']", text: "Matching gems: 0 of 65"
      assert_match "No gems match your filter.", response.body
      refute_match "This user has not pushed any gems yet.", response.body
    end

    get profile_path(user.handle), params: { gem_filter: "\uFEFFSDK\u00A0AwS\u2003", sort: "name" }

    assert_equal(matches.first(30), css_select("h4").map { it.text.strip })

    get profile_path(user.handle), params: { gem_filter: " \t\u00A0\u2003\uFEFF ", sort: "name" }

    assert_select "h4", count: 30
    assert_select "[role='status']", text: "65 gems"

    get profile_path(create(:user).handle)

    assert_response :success
    assert_match "This user has not pushed any gems yet.", response.body
    assert_select "input[aria-label='Filter by gem name']", count: 0
    assert_select "nav[aria-label='Pagination']", count: 0
  end
end
