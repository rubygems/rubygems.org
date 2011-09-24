require File.expand_path("../../../test_helper", __FILE__)

class RubygemsHelperTest < ActionView::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  should "create the directory" do
    directory = link_to_directory
    ("A".."Z").each do |letter|
      assert_match rubygems_path(:letter => letter), directory
    end
  end

  should "know when to show the all versions link" do
    rubygem = stub
    stub(rubygem).versions_count { 6 }
    stub(rubygem).yanked_versions? { false }
    assert show_all_versions_link?(rubygem)
    stub(rubygem).versions_count { 1 }
    stub(rubygem).yanked_versions? { false }
    assert !show_all_versions_link?(rubygem)
    stub(rubygem).yanked_versions? { true }
    assert show_all_versions_link?(rubygem)
  end

  should "show a nice formatted date" do
    Timecop.travel(Date.parse("2011-03-18")) do
      assert_equal "March 18, 2011", nice_date_for(DateTime.now)
    end
  end

  should "link to docs if no docs link is set" do
    version = FactoryGirl.build(:version)
    linkset = FactoryGirl.build(:linkset, :docs => nil)

    link = documentation_link(version, linkset)
    assert link.include?(documentation_path(version))
  end

  should "not link to docs if docs link is set" do
    version = FactoryGirl.build(:version)
    linkset = FactoryGirl.build(:linkset)

    link = documentation_link(version, linkset)
    assert link.blank?
  end

  context "creating linkset links" do
    setup do
      @linkset = FactoryGirl.build(:linkset)
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

  context "options for individual stats" do
    setup do
      @rubygem = Factory(:rubygem)
      @versions = (1..3).map { Factory(:version, :rubygem => @rubygem) }
    end

    should "show the overview link first" do
      overview = stats_options(@rubygem).first
      assert_equal ["Overview", rubygem_stats_path(@rubygem)], overview
    end

    should "have all the links for the rubygem" do
      _, *links = stats_options(@rubygem)

      @versions.sort.reverse.each_with_index do |version, index|
        assert_equal [version.slug, rubygem_version_stats_path(@rubygem, version.slug)], links[index]
      end
    end
  end

  context "profiles" do
    setup do
      fake_request = stub
      stub(fake_request).ssl? { false }
      stub(self).request { fake_request }
    end

    should "create links to owners gem overviews" do
      users = Array.new(2) { Factory(:user) }
      create_gem(*users)
      expected_links = users.sort_by(&:id).map { |u|
        link_to gravatar(48, "gravatar-#{u.id}", u), profile_path(u.display_id), :alt => u.display_handle,
          :title => u.display_handle
      }.join
      assert_equal expected_links, links_to_owners(@rubygem)
      assert links_to_owners(@rubygem).html_safe?
    end
  end
end
