require 'test_helper'

class RubygemsHelperTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  should "create the directory" do
    directory = link_to_directory
    ("A".."Z").each do |letter|
      assert_match rubygems_path(:letter => letter), directory
    end
  end

  should "link to docs if no docs link is set" do
    version = Factory.build(:version)
    linkset = Factory.build(:linkset, :docs => nil)
    
    link = documentation_link(version, linkset)
    assert link.include?(documentation_path(version))
  end

  should "not link to docs if docs link is set" do
    version = Factory.build(:version)
    linkset = Factory.build(:linkset)
    
    link = documentation_link(version, linkset)
    assert link.blank?
  end

  context "creating linkset links" do
    setup do
      @linkset = Factory.build(:linkset)
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
      assert_equal ["Overview", stats_rubygem_path(@rubygem)], overview
    end

    should "have all the links for the rubygem" do
      _, *links = stats_options(@rubygem)

      @versions.sort.reverse.each_with_index do |version, index|
        assert_equal [version.slug, stats_rubygem_version_path(@rubygem, version.slug)], links[index]
      end
    end
  end
end
