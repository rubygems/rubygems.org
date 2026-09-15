# frozen_string_literal: true

require "test_helper"

class GemsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
  end

  test "gem page with a non valid HTTP_ACCEPT header" do
    get rubygem_path(@rubygem.slug), headers: { "HTTP_ACCEPT" => "application/mercurial-0.1" }

    assert page.has_content? "1.0.0"
  end

  test "gems page with atom format" do
    get rubygems_path(format: :atom)

    assert_response :success
    assert_equal "application/atom+xml", response.media_type
    assert page.has_content? "sandworm"
  end

  test "versions with atom format" do
    create(:version, rubygem: @rubygem)
    get rubygem_versions_path(@rubygem.slug, format: :atom)

    assert_equal "application/atom+xml", response.media_type
    assert page.has_content? "sandworm"
  end

  test "canonical/alternate urls for gem points to most recent version" do
    skip "locales temporarily disabled"

    base_url = "http://localhost/gems/sandworm/versions/1.1.1"
    create(:version, rubygem: @rubygem, number: "1.1.1")
    get rubygem_path(@rubygem.slug)
    css = %(link[rel="canonical"][href="#{base_url}"])

    assert page.has_css?(css, visible: false)
    css = %(link[rel="alternate"][hreflang])
    alternates = page.all(:css, css, visible: false)
    # I18n.available_locales.length + 1 (x-default)
    assert_equal (I18n.available_locales.length + 1), alternates.length
    exp = I18n.available_locales.map { "#{base_url}?locale=#{it}" } << base_url
    act = alternates.pluck(:href)

    assert_same_elements exp, act
  end

  test "canonical locale urls for gem points to most recent version without locale" do
    create(:version, rubygem: @rubygem, number: "1.1.1")
    get rubygem_path(@rubygem.slug, locale: "en")
    css = %(link[rel="canonical"][href="http://localhost/gems/sandworm/versions/1.1.1"])

    assert page.has_css?(css, visible: false)
  end

  test "canonical url for an old version" do
    create(:version, rubygem: @rubygem, number: "1.1.1")
    get rubygem_version_path(@rubygem.slug, "1.0.0")
    css = %(link[rel="canonical"][href="http://localhost/gems/sandworm/versions/1.0.0"])

    assert page.has_css?(css, visible: false)
  end

  test "letter param is not string" do
    get rubygems_path(letter: ["S"])

    assert_response :success
  end

  test "anonymous gem index request sets public cache headers" do
    get rubygems_path(letter: "S")

    assert_response :success
    assert_nil response.headers["Set-Cookie"]
    assert_includes response.headers["Cache-Control"], "public"
    assert_includes response.headers["Surrogate-Control"], "max-age=60"
    assert_equal "gems/index", response.headers["Surrogate-Key"]
  end

  test "anonymous gem show request does not set a session cookie" do
    get rubygem_path(@rubygem.slug)

    assert_response :success
    assert_nil response.headers["Set-Cookie"]
  end

  test "anonymous gem show request sets public cache headers" do
    get rubygem_path(@rubygem.slug)

    assert_response :success
    assert_includes response.headers["Cache-Control"], "public"
    assert_includes response.headers["Surrogate-Control"], "max-age=60"
    assert_equal "gem/sandworm", response.headers["Surrogate-Key"]
  end

  test "authenticated gem show request does not set public cache headers" do
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    get rubygem_path(@rubygem.slug)

    assert_response :success
    assert_includes response.headers["Set-Cookie"].to_s, "_rubygems_session"
    refute_includes response.headers["Cache-Control"], "public"
  end
end
