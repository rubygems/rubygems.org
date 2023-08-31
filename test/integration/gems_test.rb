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
    base_url = "http://localhost/gems/sandworm/versions/1.1.1".freeze
    create(:version, rubygem: @rubygem, number: "1.1.1")
    get rubygem_path(@rubygem.slug)
    css = %(link[rel="canonical"][href="#{base_url}"])

    assert page.has_css?(css, visible: false)
    css = %(link[rel="alternate"][hreflang])
    alternates = page.all(:css, css, visible: false)
    # I18n.available_locales.length + 1 (x-default)
    assert_equal (I18n.available_locales.length + 1), alternates.length
    exp = I18n.available_locales.map { "#{base_url}?locale=#{_1}" } << base_url
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
end

class GemsSystemTest < SystemTest
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    @version = create(:version, rubygem: @rubygem, number: "1.1.1")
  end

  test "version navigation" do
    visit rubygem_version_path(@rubygem.slug, "1.0.0")
    click_link "Next version →"

    assert_equal page.current_path, rubygem_version_path(@rubygem.slug, "1.1.1")
    click_link "← Previous version"

    assert_equal page.current_path, rubygem_version_path(@rubygem.slug, "1.0.0")
  end

  test "subscribe to a gem" do
    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert page.has_css?("a#subscribe")

    click_link "Subscribe"

    assert page.has_content? "Unsubscribe"
    assert_equal @user.subscribed_gems.first, @rubygem
  end

  test "unsubscribe to a gem" do
    create(:subscription, rubygem: @rubygem, user: @user)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert page.has_css?("a#unsubscribe")

    click_link "Unsubscribe"

    assert page.has_content? "Subscribe"
    assert_empty @user.subscribed_gems
  end

  test "shows enable MFA instructions when logged in as owner with MFA disabled" do
    create(:ownership, rubygem: @rubygem, user: @user)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert page.has_selector?(".gem__users__mfa-disabled .gem__users a")
    assert page.has_content? "Please consider enabling multi-factor"
  end

  test "shows owners without mfa when logged in as owner" do
    @user.enable_totp!("some-seed", "ui_and_api")
    user_without_mfa = create(:user)

    create(:ownership, rubygem: @rubygem, user: @user)
    create(:ownership, rubygem: @rubygem, user: user_without_mfa)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert page.has_selector?(".gem__users__mfa-disabled .gem__users a")
    assert page.has_selector?(".gem__users__mfa-text.mfa-warn")
  end

  test "show mfa enabled when logged in as owner but everyone has mfa enabled" do
    @user.enable_totp!("some-seed", "ui_and_api")
    user_with_mfa = create(:user)
    user_with_mfa.enable_totp!("some-seed", "ui_and_api")

    create(:ownership, rubygem: @rubygem, user: @user)
    create(:ownership, rubygem: @rubygem, user: user_with_mfa)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert page.has_no_selector?(".gem__users__mfa-text.mfa-warn")
    assert page.has_selector?(".gem__users__mfa-text.mfa-info")
  end

  test "does not show owners without mfa when not logged in as owner" do
    @user.enable_totp!("some-seed", "ui_and_api")
    user_without_mfa = create(:user)

    create(:ownership, rubygem: @rubygem, user: @user)
    create(:ownership, rubygem: @rubygem, user: user_without_mfa)

    visit rubygem_path(@rubygem.slug)

    assert page.has_no_selector?(".gem__users__mfa-disabled .gem__users a")
    assert page.has_no_selector?(".gem__users__mfa-text.mfa-warn")
    assert page.has_no_selector?(".gem__users__mfa-text.mfa-info")
  end

  test "shows github link when source_code_uri is set" do
    github_link = "http://github.com/user/project"
    create(:version, number: "3.0.1", rubygem: @rubygem, metadata: { "source_code_uri" => github_link })

    visit rubygem_path(@rubygem.slug)

    assert page.has_selector?(".github-btn")
  end

  test "shows github link when homepage_uri is set" do
    github_link = "http://github.com/user/project"
    create(:version, number: "3.0.1", rubygem: @rubygem, metadata: { "homepage_uri" => github_link })

    visit rubygem_path(@rubygem.slug)

    assert page.has_selector?(".github-btn")
  end

  test "does not show github link when homepage_uri is not github" do
    notgithub_link = "http://notgithub.com/user/project"
    create(:version, number: "3.0.1", rubygem: @rubygem, metadata: { "homepage_uri" => notgithub_link })

    visit rubygem_path(@rubygem.slug)

    assert page.has_no_selector?(".github-btn")
  end

  test "shows both mfa headers if latest AND viewed version require MFA" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "true" }
    create(:version, :mfa_required, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    assert page.has_content? "New versions require MFA"
    assert page.has_content? "Version published with MFA"
  end

  test "shows 'new' mfa header only if latest requires MFA but viewed version doesn't" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "true" }
    create(:version, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    assert page.has_content? "New versions require MFA"
    refute page.has_content? "Version published with MFA"
  end

  test "shows 'version' mfa header only if latest does not require MFA but viewed version does" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }
    create(:version, :mfa_required, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    refute page.has_content? "New versions require MFA"
    assert page.has_content? "Version published with MFA"
  end

  test "does not show either mfa header if neither latest or viewed version require MFA" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }
    create(:version, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    refute page.has_content? "New versions require MFA"
    refute page.has_content? "Version published with MFA"
  end

  test "shows both mfa headers if MFA enabled for latest version and viewing latest version" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "true" }

    visit rubygem_path(@rubygem.slug)

    assert page.has_content? "New versions require MFA"
    assert page.has_content? "Version published with MFA"
  end

  test "shows neither mfa header if MFA disabled for latest version and viewing latest version" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }

    visit rubygem_path(@rubygem.slug)

    refute page.has_content? "New versions require MFA"
    refute page.has_content? "Version published with MFA"
  end
end
