require 'test_helper'

class RubygemsHelperTest < ActionView::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ERB::Util

  should "create the directory" do
    directory = link_to_directory
    ("A".."Z").each do |letter|
      assert_match rubygems_path(:letter => letter), directory
    end
  end

  should "know when to show the all versions link" do
    rubygem = stub
    rubygem.stubs(:versions_count).returns 6
    rubygem.stubs(:yanked_versions?).returns false
    assert show_all_versions_link?(rubygem)
    rubygem.stubs(:versions_count).returns 1
    rubygem.stubs(:yanked_versions?).returns false
    assert !show_all_versions_link?(rubygem)
    rubygem.stubs(:yanked_versions?).returns true
    assert show_all_versions_link?(rubygem)
  end

  should "show a nice formatted date" do
    Timecop.travel(DateTime.parse("2011-03-18T00:00:00-00:00")) do
      assert_equal "March 18, 2011", nice_date_for(DateTime.now.utc)
    end
  end

  should "link to docs if no docs link is set" do
    version = build(:version)
    linkset = build(:linkset, :docs => nil)

    link = documentation_link(version, linkset)
    assert link.include?(version.documentation_path)
  end

  should "not link to docs if docs link is set" do
    version = build(:version)
    linkset = build(:linkset)

    link = documentation_link(version, linkset)
    assert link.blank?
  end

  should "link to the badge" do
    rubygem = create(:rubygem)
    url = "http://badge.fury.io/rb/#{rubygem.name}/install"
    assert_match url, badge_link(rubygem)
  end

  should "link to report abuse" do
    rubygem = create(:rubygem, :name => 'my_gem')
    url = "http://help.rubygems.org/discussion/new?discussion[title]=Reporting%20Abuse%20on%20my_gem&discussion[private]=1"
    assert_match url, report_abuse_link(rubygem)
  end

  context "creating linkset links" do
    setup do
      @linkset = build(:linkset)
      @linkset.wiki = nil
      @linkset.code = ""
    end

    should "create link for homepage" do
      assert_match @linkset.home, link_to_page("Homepage", @linkset.home)
    end

    should "be a nofollow link" do
      assert_match 'rel="nofollow"', link_to_page("Homepage", @linkset.home)
    end

    should "not create link for wiki" do
      assert_nil link_to_page("Wiki", @linkset.wiki)
    end

    should "not create link for code" do
      assert_nil link_to_page("Code", @linkset.code)
    end
  end

  context "profiles" do
    setup do
      fake_request = stub
      fake_request.stubs(:ssl?).returns false
      self.stubs(:request).returns fake_request
    end

    should "create links to owners gem overviews" do
      users = Array.new(2) { create(:user) }
      @rubygem = create(:rubygem, owners: users)

      expected_links = users.sort_by(&:id).map { |u|
        link_to gravatar(48, "gravatar-#{u.id}", u), profile_path(u.display_id), :alt => u.display_handle,
          :title => u.display_handle
      }.join
      assert_equal expected_links, links_to_owners(@rubygem)
      assert links_to_owners(@rubygem).html_safe?
    end
  end

  context 'simple_markup' do
    should 'sanitize copy' do
      text = '<script>alert("foo");</script>Rails authentication & authorization'
      assert_equal '<p>Rails authentication &amp; authorization</p>', simple_markup(text)
      assert simple_markup(text).html_safe?
    end

    should 'work on rdoc strings' do
      text = '== FOO'
      assert_equal "\n<h2 id=\"label-FOO\">FOO</h2>\n", simple_markup(text)
      assert simple_markup(text).html_safe?
    end
  end
end
