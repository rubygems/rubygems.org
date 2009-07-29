require 'test_helper'

class RubygemsHelperTest < ActionView::TestCase
  should "create the directory" do
    directory = link_to_directory
    ("A".."Z").each do |letter|
      assert_match rubygems_path(:letter => letter), directory
    end
  end

  context "creating linkset links" do
    setup do
      @linkset = Factory.build(:linkset)
      @linkset.wiki = nil
      @linkset.code = ""
    end

    should "create link for homepage" do
      assert_equal link_to_page("Homepage", @linkset.home),
        %{<a href="#{@linkset.home}">Homepage</a>}
    end

    should "not create link for wiki" do
      assert_nil link_to_page("Wiki", @linkset.wiki)
    end

    should "not create link for code" do
      assert_nil link_to_page("Code", @linkset.code)
    end
  end
end
