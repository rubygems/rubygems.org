require "test_helper"

class RubygemsHelperTest < ActionView::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ERB::Util

  context "licenses header" do
    setup do
      @version = build(:version)
    end
    should "singular if version has one license" do
      @version.stubs(:licenses).returns(["MIT"])
      assert_equal "License", pluralized_licenses_header(@version)
    end
    should "plural if version has no license or more than one license" do
      @version.stubs(:licenses)
      assert_equal "Licenses", pluralized_licenses_header(@version)

      @version.stubs(:licenses).returns(%w[MIT GPL-2])
      assert_equal "Licenses", pluralized_licenses_header(@version)
    end
  end

  context "formatted licenses" do
    should "be N/A if there is no license" do
      assert_equal "N/A", formatted_licenses([])
    end

    should "be combined with comma if there are licenses" do
      assert_equal "MIT, GPL-2", formatted_licenses(%w[MIT GPL-2])
    end
  end

  should "create the directory" do
    directory = link_to_directory
    ("A".."Z").each do |letter|
      assert_match rubygems_path(letter: letter), directory
    end
  end

  should "know when to show the all versions link" do
    rubygem = stub
    rubygem.stubs(:versions_count).returns 6
    rubygem.stubs(:yanked_versions?).returns false
    assert show_all_versions_link?(rubygem)
    rubygem.stubs(:versions_count).returns 1
    rubygem.stubs(:yanked_versions?).returns false
    refute show_all_versions_link?(rubygem)
    rubygem.stubs(:yanked_versions?).returns true
    assert show_all_versions_link?(rubygem)
  end

  should "show a nice formatted date" do
    time = Time.zone.parse("2011-03-18T00:00:00-00:00")
    assert_equal "March 18, 2011", nice_date_for(time)
  end

  should "link to the badge" do
    rubygem = create(:rubygem)
    url = "https://badge.fury.io/rb/#{rubygem.name}/install"

    assert_match url, badge_link(rubygem)
  end

  should "link to report abuse" do
    rubygem = create(:rubygem, name: "my_gem")
    url = "mailto:support@rubygems.org?subject=Reporting Abuse on my_gem"

    assert_match url, report_abuse_link(rubygem)
  end

  context "creating linkset links" do
    setup do
      @linkset = build(:linkset)
      @linkset.wiki = nil
      @linkset.code = ""
    end

    should "create link for homepage" do
      assert_match @linkset.home, link_to_page(:home, @linkset.home)
    end

    should "be a nofollow link" do
      assert_match 'rel="nofollow"', link_to_page(:home, @linkset.home)
    end

    should "not create link for wiki" do
      assert_nil link_to_page(:wiki, @linkset.wiki)
    end

    should "not create link for code" do
      assert_nil link_to_page(:code, @linkset.code)
    end
  end

  context "profiles" do
    setup do
      fake_request = stub
      fake_request.stubs(:ssl?).returns false
      stubs(:request).returns fake_request
    end

    should "create links to owners gem overviews" do
      users = Array.new(2) { create(:user) }
      @rubygem = create(:rubygem, owners: users)

      expected_links = users.sort_by(&:id).map do |u|
        link_to gravatar(48, "gravatar-#{u.id}", u),
          profile_path(u.display_id),
          alt: u.display_handle,
          title: u.display_handle
      end.join
      assert_equal expected_links, links_to_owners(@rubygem)
      assert_predicate links_to_owners(@rubygem), :html_safe?
    end

    should "create links to gem owners without mfa" do
      with_mfa = create(:user, mfa_level: "ui_and_api")
      without_mfa = create_list(:user, 2, mfa_level: "disabled")
      rubygem = create(:rubygem, owners: [*without_mfa, with_mfa])

      expected_links = without_mfa.sort_by(&:id).map do |u|
        link_to gravatar(48, "gravatar-#{u.id}", u),
          profile_path(u.display_id),
          alt: u.display_handle,
          title: u.display_handle
      end.join
      assert_equal expected_links, links_to_owners_without_mfa(rubygem)
      assert_predicate links_to_owners_without_mfa(rubygem), :html_safe?
    end
  end

  context "simple_markup" do
    should "sanitize copy" do
      text = '<script>alert("foo");</script>Rails authentication & authorization'
      assert_equal "<p>alert(&quot;foo&quot;);Rails authentication &amp; authorization</p>", simple_markup(text)
      assert_predicate simple_markup(text), :html_safe?
    end

    should "work on rdoc strings" do
      text = "== FOO"
      assert_equal "\n<h2>FOO</h2>\n", simple_markup(text)
      assert_predicate simple_markup(text), :html_safe?
    end

    should "sanitize rdoc strings" do
      text = "== FOO\nclick[javascript:alert('foo')]"
      assert_equal "\n<h2>FOO</h2>\n\n<p><a>click</a></p>\n", simple_markup(text)

      assert_predicate simple_markup(text), :html_safe?
    end
  end

  context "link_to_github" do
    context "with invalid uri" do
      setup do
        linkset = build(:linkset, code: "http://github.com/\#{github_username}/\#{project_name}")
        @rubygem = create(:rubygem, linkset: linkset, number: "0.0.1")
      end

      should "not raise error" do
        assert_nothing_raised { link_to_github(@rubygem) }
      end

      should "return nil" do
        assert_nil link_to_github(@rubygem)
      end
    end

    context "with valid code uri and github as host" do
      setup do
        @github_link = "http://github.com/user/project"
        linkset = build(:linkset, code: @github_link)
        @rubygem = create(:rubygem, linkset: linkset, number: "0.0.1")
      end

      should "return parsed uri" do
        assert_equal URI(@github_link), link_to_github(@rubygem)
      end
    end

    context "with valid home uri and github as host" do
      setup do
        @github_link = "http://github.com/user/project"
        linkset = build(:linkset, home: @github_link)
        @rubygem = create(:rubygem, linkset: linkset, number: "0.0.1")
      end

      should "return parsed uri" do
        assert_equal URI(@github_link), link_to_github(@rubygem)
      end
    end
  end

  context "change_diff_link" do
    context "with yanked version" do
      setup do
        @version = create(:version, indexed: false)
        @rubygem = @version.rubygem
      end

      should "return nil" do
        assert_nil change_diff_link(@rubygem, @version)
      end
    end

    context "with available version" do
      setup do
        @version = create(:version)
        @rubygem = @version.rubygem
      end

      should "generate a correct link to the gem versions diff" do
        diff_url = "https://my.diffend.io/gems/#{@rubygem.name}/prev/#{@version.slug}"

        expected_link = link_to "Review changes", diff_url,
                          class: "gem__link t-list__item"

        assert_equal expected_link, change_diff_link(@rubygem, @version)
      end
    end
  end
end
