# frozen_string_literal: true

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

    assert_current_path rubygem_version_path(@rubygem.slug, "1.1.1")
    click_link "← Previous version"

    assert_current_path rubygem_version_path(@rubygem.slug, "1.0.0")
  end

  test "subscribe to a gem" do
    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert page.has_css?("a#subscribe")

    click_link "Subscribe"

    assert_text "Unsubscribe"
    assert_equal @user.subscribed_gems.first, @rubygem
  end

  test "unsubscribe to a gem" do
    create(:subscription, rubygem: @rubygem, user: @user)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert page.has_css?("a#unsubscribe")

    click_link "Unsubscribe"

    assert_text "Subscribe"
    assert_empty @user.subscribed_gems
  end

  test "shows enable MFA instructions when logged in as owner with MFA disabled" do
    create(:ownership, rubygem: @rubygem, user: @user)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert_text "Please consider enabling multi-factor"
    find(".gem__users__mfa-text.mfa-warn").click

    assert page.has_selector?(".gem__users__mfa-disabled .gem__users a")
  end

  test "shows owners without mfa when logged in as owner" do
    @user.enable_totp!("some-seed", "ui_and_api")
    user_without_mfa = create(:user)

    create(:ownership, rubygem: @rubygem, user: @user)
    create(:ownership, rubygem: @rubygem, user: user_without_mfa)

    visit rubygem_path(@rubygem.slug, as: @user.id)

    assert page.has_selector?(".gem__users__mfa-text.mfa-warn")
    find(".gem__users__mfa-text.mfa-warn").click

    assert page.has_selector?(".gem__users__mfa-disabled .gem__users a")
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

  test "shows a prior owner in the owners list" do
    former_owner = create(:user, handle: "former_owner")
    create(:ownership, rubygem: @rubygem, user: former_owner).destroy

    visit rubygem_path(@rubygem.slug)

    assert page.has_selector?("a.gem__prior-owner", text: "former_owner")
    assert_text(/until/i)
  end

  test "does not style a current owner as a prior owner" do
    current_owner = create(:user, handle: "current_owner")
    former_owner = create(:user, handle: "former_owner")
    create(:ownership, rubygem: @rubygem, user: current_owner)
    create(:ownership, rubygem: @rubygem, user: former_owner).destroy

    visit rubygem_path(@rubygem.slug)

    assert page.has_link?("current_owner", href: profile_path(current_owner.display_id))
    assert page.has_no_selector?("a.gem__prior-owner", text: "current_owner")
    assert page.has_selector?("a.gem__prior-owner", text: "former_owner")
  end

  test "does not show a discarded prior owner" do
    visible_owner = create(:user, handle: "visible_owner")
    discarded_owner = create(:user, handle: "discarded_owner")
    create(:ownership, rubygem: @rubygem, user: visible_owner).destroy
    create(:ownership, rubygem: @rubygem, user: discarded_owner).destroy
    discarded_owner.discard!

    visit rubygem_path(@rubygem.slug)

    assert page.has_selector?("a.gem__prior-owner", text: "visible_owner")
    assert page.has_no_text?("discarded_owner")
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

    assert_text "NEW VERSIONS REQUIRE MFA"
    assert_text "VERSION PUBLISHED WITH MFA"
  end

  test "shows 'new' mfa header only if latest requires MFA but viewed version doesn't" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "true" }
    create(:version, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    assert_text "NEW VERSIONS REQUIRE MFA"
    assert_no_text "VERSION PUBLISHED WITH MFA"
  end

  test "shows 'version' mfa header only if latest does not require MFA but viewed version does" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }
    create(:version, :mfa_required, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    assert_no_text "NEW VERSIONS REQUIRE MFA"
    assert_text "VERSION PUBLISHED WITH MFA"
  end

  test "does not show either mfa header if neither latest or viewed version require MFA" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }
    create(:version, rubygem: @rubygem, number: "0.1.1")

    visit rubygem_version_path(@rubygem.slug, "0.1.1")

    assert_no_text "NEW VERSIONS REQUIRE MFA"
    assert_no_text "VERSION PUBLISHED WITH MFA"
  end

  test "shows both mfa headers if MFA enabled for latest version and viewing latest version" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "true" }

    visit rubygem_path(@rubygem.slug)

    assert_text "NEW VERSIONS REQUIRE MFA"
    assert_text "VERSION PUBLISHED WITH MFA"
  end

  test "shows neither mfa header if MFA disabled for latest version and viewing latest version" do
    @version.update_attribute :metadata, { "rubygems_mfa_required" => "false" }

    visit rubygem_path(@rubygem.slug)

    assert_no_text "NEW VERSIONS REQUIRE MFA"
    assert_no_text "VERSION PUBLISHED WITH MFA"
  end
end
