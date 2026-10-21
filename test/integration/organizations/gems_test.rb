# frozen_string_literal: true

require "test_helper"

class Organizations::GemsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })
  end

  test "should get index" do
    @organization = create(:organization, owners: [@user])
    @organization.rubygems << create(:rubygem, name: "arrakis", number: "1.0.0")

    get "/organizations/#{@organization.to_param}/gems"

    assert page.has_content? "arrakis"
  end

  test "should get index with no gems" do
    @organization = create(:organization, owners: [@user])

    get "/organizations/#{@organization.to_param}/gems"

    assert page.has_content? "No gems yet"
  end

  test "visitors can traverse every organization gem in each stable sort order" do
    organization = create(:organization, owners: [@user])
    published = Time.utc(2026, 1, 1)
    # Reverse insertion order catches sorts that rely on IDs to break ties.
    gems = create_list(:rubygem, 65, organization:) do |gem, i| # rubocop:disable FactoryBot/ExcessiveCreateList
      gem.update!(name: format("pagegem-%02d", 65 - i))
      gem.gem_download.update!(count: i < 35 ? 20 : 10)
      create(:version, rubygem: gem, created_at: i < 20 ? published + 1.day : published)
    end
    names = gems.map(&:name).sort
    create(:rubygem, organization:, name: "pagegem-unpublished")
    create(:rubygem, name: "pagegem-other-organization", number: "1.0.0")
    delete sign_out_path

    orders = {
      "name" => names,
      "downloads" => names.last(35) + names.first(30),
      "recent" => names.last(20) + names.first(45)
    }
    [organization_path(organization), organization_gems_path(organization)].each do |path|
      orders.each do |sort, expected|
        visited = []
        1.upto(3) do |number|
          get path, params: { sort:, page: number }

          assert_response :success
          listed = css_select("h4").map { it.text.strip }

          assert_equal expected.slice((number - 1) * 30, 30), listed, "#{path}, #{sort}, page #{number}"
          assert_select "nav[aria-label='Pagination']"
          visited.concat(listed)
        end

        assert_equal expected, visited
        assert_equal 65, visited.uniq.size

        get path, params: { sort:, page: 4 }

        assert_response :success
        assert_select "h4", count: 0
        assert_select "nav[aria-label='Pagination'] a", minimum: 1
      end
    end
  end

  test "organization filters search all names before pagination and preserve navigation state" do
    organization = create(:organization, owners: [@user])
    create_list(:rubygem, 30, organization:) do |gem, i| # rubocop:disable FactoryBot/ExcessiveCreateList
      gem.update!(name: format("aaa-other-%02d", 30 - i))
      create(:version, rubygem: gem, number: "1.0.0")
    end
    matching_gems = create_list(:rubygem, 35, organization:) do |gem, i| # rubocop:disable FactoryBot/ExcessiveCreateList
      gem.update!(name: format("aws-sdk-%02d", 35 - i))
      create(:version, rubygem: gem, number: "1.0.0")
    end
    matches = matching_gems.map(&:name).sort
    create(:rubygem, name: "aws-sdk-outsider", number: "1.0.0")
    create(:rubygem, organization:, name: "aws-sdk-unpublished")
    query = "  SDK   AwS  "
    nonmatching_filters = ["missing", "aws%", "aws_", "aws\\", "aws\u0085sdk", "aws\u200Bsdk"]

    [organization_path(organization), organization_gems_path(organization)].each do |path|
      get path, params: { sort: "name", gem_filter: query }

      assert_response :success
      assert_equal(matches.first(30), css_select("h4").map { it.text.strip })
      assert_select "nav[aria-label='Pagination'] a[rel='next']" do |links|
        get links.first["href"]
      end

      assert_response :success
      assert_equal(matches.last(5), css_select("h4").map { it.text.strip })
      assert_equal query, request.params["gem_filter"]
      assert_equal "name", request.params["sort"]
      assert_select "[role='menuitemradio']" do |links|
        links.each do |link|
          params = Rack::Utils.parse_query(URI(link["href"]).query)

          assert_equal query, params["gem_filter"]
          assert_nil params["page"]
        end
      end

      get path, params: { sort: "name", gem_filter: "\uFEFFSDK\u00A0AwS\u2003" }

      assert_equal(matches.first(30), css_select("h4").map { it.text.strip })
      assert_select "[role='status']", text: "Matching gems: 35 of 65"

      nonmatching_filters.each do |filter|
        get path, params: { gem_filter: filter }

        assert_response :success
        assert_select "h4", count: 0
      end

      get path, params: { gem_filter: " \t\u00A0\u2003\uFEFF ", sort: "name" }

      assert_equal 30, css_select("h4").size
      assert_equal "aaa-other-01", css_select("h4").first.text.strip
      assert_select "[role='status']", text: "65 gems"
    end
  end
end
