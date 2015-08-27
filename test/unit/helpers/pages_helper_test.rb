require 'test_helper'

class PagesHelperTest < ActionView::TestCase
  include RubygemsHelper

  context "downloads" do
    setup do
      @rubygem = create(:rubygem, name: "rubygems-update")
      @version_first = create(:version, number: "1.4.8", rubygem: @rubygem)
      @version_last = create(:version,
        number: "2.4.8",
        built_at: Time.zone.local(2015, 1, 1),
        rubygem: @rubygem)
    end

    should "return latest rubygem release version number" do
      assert_equal @version_last.number, version_number
    end

    should "return 0.0.0 as version number if version doesn't exist" do
      @rubygem.versions.each(&:destroy)
      assert_equal "0.0.0", version_number
    end

    should "return latest rubygem release" do
      assert_equal @version_last, version
    end

    should "return subtitle with release date and version number if both exist" do
      assert_equal "v#{@version_last.number} - #{nice_date_for(@version_last.built_at)}", subtitle
    end

    should "return subtitle with release date and version number if built_at doesn't exist" do
      @version_last.built_at = nil
      @version_last.save
      assert_equal "v#{@version_last.number}", subtitle
    end
  end
end
