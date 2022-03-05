require "test_helper"

class Api::V1::DownloadsControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    should "return #{format.to_s.upcase} with the download count" do
      get :index, format: format
      assert_equal @count, yield(@response.body)
    end
  end

  context "On GET to index" do
    setup do
      @count = 30_000_000
      create(:gem_download, count: @count)
    end

    should "return the download count" do
      get :index
      assert_equal @count, @response.body.to_i
    end

    should_respond_to(:json) do |body|
      JSON.load(body)["total"]
    end

    should_respond_to(:yaml) do |body|
      YAML.safe_load(body, permitted_classes: [Symbol])[:total]
    end

    should_respond_to(:text, &:to_i)
  end

  def get_show(version, format = "json")
    get :show, params: { id: version.full_name }, format: format
  end

  def self.should_respond_to(format, to_meth = :to_s)
    context "with #{format.to_s.upcase}" do
      should "have total downloads for version1" do
        get_show(@version1, format)
        assert_equal 3, yield(@response.body)["total_downloads".send(to_meth)]
      end

      should "have downloads for the most recent version of version1" do
        get_show(@version1, format)
        assert_equal 1, yield(@response.body)["version_downloads".send(to_meth)]
      end

      should "have total downloads for version2" do
        get_show(@version2, format)
        assert_equal 3, yield(@response.body)["total_downloads".send(to_meth)]
      end

      should "have downloads for the most recent version of version2" do
        get_show(@version2, format)
        assert_equal 2, yield(@response.body)["version_downloads".send(to_meth)]
      end
    end
  end

  context "on GET to show" do
    setup do
      rubygem = create(:rubygem)
      @version1 = create(:version, rubygem: rubygem, number: "1.0.0")
      @version2 = create(:version, rubygem: rubygem, number: "2.0.0")

      GemDownload.bulk_update([[@version1.full_name, 1], [@version2.full_name, 2]])
    end

    should_respond_to(:json) do |body|
      JSON.load body
    end

    should_respond_to(:yaml, :to_sym) do |body|
      YAML.safe_load(body, permitted_classes: [Symbol])
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get :show, params: { id: "rials" }, format: "json"
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end

  context "on GET to show for a yanked gem" do
    setup do
      rubygem = create(:rubygem)
      @version = create(:version, rubygem: rubygem, number: "1.0.0", indexed: false)
      get_show(@version)
    end

    should respond_with :success
  end

  context "On GET to all" do
    setup do
      @rubygem_1 = create(:rubygem)
      @version_1 = create(:version, rubygem: @rubygem_1)
      @version_2 = create(:version, rubygem: @rubygem_1)

      @rubygem_2 = create(:rubygem)
      @version_3 = create(:version, rubygem: @rubygem_2)

      @rubygem_3 = create(:rubygem)
      @version_4 = create(:version, rubygem: @rubygem_3)

      GemDownload.bulk_update([[@version_1.full_name, 3], [@version_2.full_name, 2], [@version_3.full_name, 1]])
    end

    context "with json" do
      setup do
        get :all, format: "json"
        @json = JSON.load(@response.body)
      end

      should "show all latest versions" do
        assert_equal 4, @json["gems"].count
      end

      should "have downloads for the top version" do
        assert_equal 3, @json["gems"].first[1]
      end

      should "have total downloads for version2" do
        assert_equal 2, @json["gems"][1][1]
      end
    end
  end
end
