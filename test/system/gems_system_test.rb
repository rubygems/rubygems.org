require "application_system_test_case"

class GemsSystemTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    @version = create(:version, rubygem: @rubygem, number: "1.1.1")
  end

  test "version navigation" do
    visit rubygem_version_path(@rubygem.slug, "1.0.0")
    click_link "Next version →"

    assert_equal current_path, rubygem_version_path(@rubygem.slug, "1.1.1")
    click_link "← Previous version"

    assert_equal current_path, rubygem_version_path(@rubygem.slug, "1.0.0")
  end

  test "subscribe to a gem" do
    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert has_css?("a#subscribe")

    click_link "Subscribe"

    assert has_content? "Unsubscribe"
    assert_equal @user.subscribed_gems.first, @rubygem
  end

  test "unsubscribe to a gem" do
    create(:subscription, rubygem: @rubygem, user: @user)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert has_css?("a#unsubscribe")

    click_link "Unsubscribe"

    assert has_content? "Subscribe"
    assert_empty @user.subscribed_gems
  end

  test "shows enable MFA instructions when logged in as owner with MFA disabled" do
    create(:ownership, rubygem: @rubygem, user: @user)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert has_content? "Please consider enabling multi-factor"
  end

  test "shows owners without mfa when logged in as owner" do
    @user.enable_totp!("some-seed", "ui_and_api")
    user_without_mfa = create(:user)

    create(:ownership, rubygem: @rubygem, user: @user)
    create(:ownership, rubygem: @rubygem, user: user_without_mfa)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert has_content? "* Some owners are not using multi-factor authentication (MFA)"
  end

  test "show mfa enabled when logged in as owner but everyone has mfa enabled" do
    @user.enable_totp!("some-seed", "ui_and_api")
    user_with_mfa = create(:user)
    user_with_mfa.enable_totp!("some-seed", "ui_and_api")

    create(:ownership, rubygem: @rubygem, user: @user)
    create(:ownership, rubygem: @rubygem, user: user_with_mfa)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert has_no_selector?(".gem__users__mfa-text.mfa-warn")
    assert has_selector?(".gem__users__mfa-text.mfa-info")
  end

  test "does not show owners without mfa when not logged in as owner" do
    @user.enable_totp!("some-seed", "ui_and_api")
    user_without_mfa = create(:user)

    create(:ownership, rubygem: @rubygem, user: @user)
    create(:ownership, rubygem: @rubygem, user: user_without_mfa)

    visit rubygem_path(@rubygem.slug)

    assert has_no_selector?(".gem__users__mfa-disabled .gem__users a")
    assert has_no_selector?(".gem__users__mfa-text.mfa-warn")
    assert has_no_selector?(".gem__users__mfa-text.mfa-info")
  end

  test "shows github link when source_code_uri is set" do
    github_link = "http://github.com/user/project"
    create(:version, number: "3.0.1", rubygem: @rubygem, metadata: { "source_code_uri" => github_link })

    visit rubygem_path(@rubygem.slug)

    assert has_selector?(".github-btn")
  end

  test "shows github link when homepage_uri is set" do
    github_link = "http://github.com/user/project"
    create(:version, number: "3.0.1", rubygem: @rubygem, metadata: { "homepage_uri" => github_link })

    visit rubygem_path(@rubygem.slug)

    assert has_selector?(".github-btn")
  end

  test "does not show github link when homepage_uri is not github" do
    notgithub_link = "http://notgithub.com/user/project"
    create(:version, number: "3.0.1", rubygem: @rubygem, metadata: { "homepage_uri" => notgithub_link })

    visit rubygem_path(@rubygem.slug)

    assert has_no_selector?(".github-btn")
  end

  test "shows both mfa headers if latest AND viewed version require MFA" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "true" }
    create(:version, :mfa_required, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    assert has_content? "NEW VERSIONS REQUIRE MFA"
    assert has_content? "VERSION PUBLISHED WITH MFA"
  end

  test "shows 'new' mfa header only if latest requires MFA but viewed version doesn't" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "true" }
    create(:version, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    assert has_content? "NEW VERSIONS REQUIRE MFA"
    refute has_content? "VERSION PUBLISHED WITH MFA"
  end

  test "shows 'version' mfa header only if latest does not require MFA but viewed version does" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }
    create(:version, :mfa_required, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    refute has_content? "NEW VERSIONS REQUIRE MFA"
    assert has_content? "VERSION PUBLISHED WITH MFA"
  end

  test "does not show either mfa header if neither latest or viewed version require MFA" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }
    create(:version, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    refute has_content? "NEW VERSIONS REQUIRE MFA"
    refute has_content? "VERSION PUBLISHED WITH MFA"
  end

  test "shows both mfa headers if MFA enabled for latest version and viewing latest version" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "true" }

    visit rubygem_path(@rubygem.slug)

    assert has_content? "NEW VERSIONS REQUIRE MFA"
    assert has_content? "VERSION PUBLISHED WITH MFA"
  end

  test "shows neither mfa header if MFA disabled for latest version and viewing latest version" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }

    visit rubygem_path(@rubygem.slug)

    refute has_content? "NEW VERSIONS REQUIRE MFA"
    refute has_content? "VERSION PUBLISHED WITH MFA"
  end
end
