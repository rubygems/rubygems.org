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

    assert_text "Dashboard"
  end

  test "view yanked gem" do
    create(:version, rubygem: @rubygem, number: "1.1.1")
    create(:version, rubygem: @rubygem, number: "2.2.2")

    yank_gem_via_api(@user_api_key, @rubygem.name, "2.2.2")

    visit dashboard_path

    assert_text "sandworm"

    click_link "sandworm"

    assert_text("1.1.1")
    assert_no_text("2.2.2")

    within ".versions" do
      click_link "Show all versions (2 total)"
    end
    click_link "2.2.2"

    assert_text "This version has been yanked"
    assert page.has_css? 'meta[name="robots"][content="noindex"]', visible: false

    assert_text("YANKED BY")

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

    assert_text "sandworm"
    assert_text "0.0.0"

    yank_gem_via_api(@user_api_key, @rubygem.name, "0.0.0")

    visit rubygem_path(@rubygem.slug)

    assert_text "sandworm"
    assert_text "This gem is not currently hosted on RubyGems.org"

    other_user_key = "12323"
    other_api_key = create(:api_key, key: other_user_key, scopes: %i[push_rubygem])

    gem_io = build_gem(new_gemspec("sandworm", "1.0.0", "Gemcutter", "ruby"))
    push_gem_via_api(other_user_key, gem_io)

    visit rubygem_path(@rubygem.slug)

    assert_text "sandworm"
    assert_text "1.0.0"
    assert page.has_selector?("a[alt='#{other_api_key.user.handle}']")
    assert_no_text("0.0.0")
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

  def push_gem_via_api(api_key, gem)
    uri = URI(api_url(api_v1_rubygems_path))
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = api_key
    req["Content-Type"] = "application/octet-stream"
    req.body = gem.respond_to?(:string) ? gem.string : File.binread(gem)
    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    assert_kind_of Net::HTTPSuccess, response, "Push API failed: #{response.code} #{response.body}"
  end
end
