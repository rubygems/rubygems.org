require "application_system_test_case"
require "net/http"

class YankTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, password: PasswordHelpers::SECURE_TEST_PASSWORD)
    @rubygem = create(:rubygem, name: "sandworm")
    create(:ownership, user: @user, rubygem: @rubygem)

    @user_api_key = "12345"
    create(:api_key, owner: @user, key: @user_api_key, scopes: %i[yank_rubygem])
    Dir.chdir(Dir.mktmpdir)

    visit sign_in_path
    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign in"

    assert page.has_content? "Dashboard"
  end

  test "view yanked gem" do
    create(:version, rubygem: @rubygem, number: "1.1.1")
    create(:version, rubygem: @rubygem, number: "2.2.2")

    yank_gem_via_api(@user_api_key, @rubygem.name, "2.2.2")

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

    assert page.has_content?("YANKED BY")

    css = %(div.gem__users a[alt=#{@user.handle}])

    assert page.has_css?(css, count: 2)

    assert_event Events::RubygemEvent::VERSION_YANKED, {
      number: "2.2.2",
      platform: "ruby",
      yanked_by: @user.handle,
      version_gid: Version.last.to_gid_param,
      actor_gid: @user.to_gid.to_s
    }, @rubygem.events.where(tag: Events::RubygemEvent::VERSION_YANKED).sole
  end

  test "yanked gem entirely then someone else pushes a new version" do
    create(:version, rubygem: @rubygem, number: "0.0.0")

    visit rubygem_path(@rubygem.slug)

    assert page.has_content? "sandworm"
    assert page.has_content? "0.0.0"

    yank_gem_via_api(@user_api_key, @rubygem.name, "0.0.0")

    visit rubygem_path(@rubygem.slug)

    assert page.has_content? "sandworm"
    assert page.has_content? "This gem is not currently hosted on RubyGems.org"

    other_user_key = "12323"
    other_api_key = create(:api_key, key: other_user_key, scopes: %i[push_rubygem])

    build_gem "sandworm", "1.0.0"
    push_gem_via_api(other_user_key, "sandworm-1.0.0.gem")

    visit rubygem_path(@rubygem.slug)

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

  private

  def api_url(path)
    server = Capybara.current_session.server
    "http://#{server.host}:#{server.port}#{path}"
  end

  def yank_gem_via_api(api_key, gem_name, version)
    uri = URI(api_url(yank_api_v1_rubygems_path(gem_name: gem_name, version: version)))
    req = Net::HTTP::Delete.new(uri)
    req["Authorization"] = api_key
    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    assert_kind_of Net::HTTPSuccess, response, "Yank API failed: #{response.code} #{response.body}"
  end

  def push_gem_via_api(api_key, gem_file_path)
    uri = URI(api_url(api_v1_rubygems_path))
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = api_key
    req["Content-Type"] = "application/octet-stream"
    req.body = File.binread(gem_file_path)
    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    assert_kind_of Net::HTTPSuccess, response, "Push API failed: #{response.code} #{response.body}"
  end
end
