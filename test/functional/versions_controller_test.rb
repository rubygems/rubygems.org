require "test_helper"

class VersionsControllerTest < ActionController::TestCase
  context "GET to index" do
    setup do
      @rubygem = create(:rubygem)
      @versions = (1..5).map do
        create(:version, rubygem: @rubygem)
      end

      get :index, params: { rubygem_id: @rubygem.name }
    end

    should respond_with :success

    should "show all related versions" do
      @versions.each do |version|
        assert page.has_content?(version.number)
      end
    end
  end

  context "GET to index as an atom feed" do
    setup do
      @rubygem = create(:rubygem)
      @versions = (1..5).map do
        create(:version, rubygem: @rubygem)
      end
      @rubygem.reload

      get :index, params: { rubygem_id: @rubygem.name, format: "atom" }
    end

    should respond_with :success

    should "render correct gem information in the feed" do
      assert_select "feed > title", count: 1, text: /#{@rubygem.name}/
      assert_select "feed > updated", count: 1, text: @rubygem.updated_at.iso8601
    end

    should "render information about versions" do
      @versions.each do |v|
        assert_select "entry > title", count: 1, text: v.to_title
        assert_select "entry > link[href='#{rubygem_version_url(v.rubygem, v.slug)}']", count: 1
        assert_select "entry > id", count: 1, text: rubygem_version_url(v.rubygem, v.slug)
        # assert_select "entry > updated", :count => @versions.count, :text => v.created_at.iso8601
      end
    end
  end

  context "GET to index for gem with no versions" do
    setup do
      @rubygem = create(:rubygem)
      get :index, params: { rubygem_id: @rubygem.name }
    end

    should respond_with :success
    should "show not hosted notice" do
      assert page.has_content?("This gem is not currently hosted")
    end
    should "not show checksum" do
      assert page.has_no_content?("Sha 256 checksum")
    end
  end

  context "on GET to index with imported versions" do
    setup do
      @built_at = Date.parse("2000-01-01")
      rubygem = create(:rubygem)
      create(:version, number: "1.1.2", rubygem: rubygem, created_at: Version::RUBYGEMS_IMPORT_DATE, built_at: @built_at)
      get :index, params: { rubygem_id: rubygem.name }
    end

    should respond_with :success

    should "show imported version number with an superscript asterisk and a tooltip" do
      tooltip_text = <<~NOTICE.squish
        This gem version was imported to RubyGems.org on July 25, 2009.
        The date displayed was specified by the author in the gemspec.
      NOTICE

      assert_select ".gem__version__date", text: "- January 01, 2000*", count: 1 do |elements|
        version = elements.first
        assert_equal(tooltip_text, version["data-tooltip"])
      end

      assert_select ".gem__version__date sup", text: "*", count: 1
    end
  end

  context "On GET to show" do
    setup do
      @latest_version = create(:version, built_at: 1.week.ago, created_at: 1.day.ago)
      @rubygem = @latest_version.rubygem
      @versions = (1..5).map do
        FactoryBot.create(:version, rubygem: @rubygem)
      end
      get :show, params: { rubygem_id: @rubygem.name, id: @latest_version.number }
    end

    should respond_with :success
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
    end
    should "render the specified version" do
      assert page.has_content?(@latest_version.number)
    end
    should "render other related versions" do
      @versions.each do |version|
        assert page.has_content?(version.number)
      end
    end
    should "render the checksum version" do
      assert page.has_content?(@latest_version.sha256_hex)
    end
  end

  context "On GET to show with *a* yanked version" do
    setup do
      @version = create(:version, number: "1.0.1")
      create(:ownership, rubygem: @version.rubygem, user: create(:user, handle: "johndoe"))
      create(:version, number: "1.0.2", rubygem: @version.rubygem, indexed: false)
      get :show, params: { rubygem_id: @version.rubygem.name, id: "1.0.2" }
    end

    should respond_with :success
    should "show yanked notice" do
      assert page.has_content?("This version has been yanked")
    end
    should "render other versions" do
      assert page.has_content?("Versions")
      assert page.has_content?(@version.number)
      css = "small:contains('#{@version.authored_at.to_date.to_fs(:long)}')"
      assert page.has_css?(css)
    end
    should "renders owner gems overview link" do
      assert page.has_selector?("a[href='#{profile_path('johndoe')}']")
    end
  end
end
