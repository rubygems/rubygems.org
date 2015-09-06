require 'test_helper'

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
      Download.stubs(:count).returns @count
    end

    should "return the download count" do
      get :index
      assert_equal @count, @response.body.to_i
    end

    should_respond_to(:json) do |body|
      MultiJson.load(body)['total']
    end

    should_respond_to(:yaml) do |body|
      YAML.load(body)[:total]
    end

    should_respond_to(:text, &:to_i)
  end

  def get_show(version, format = 'json')
    get :show, id: version.full_name, format: format
  end

  def self.should_respond_to(format, to_meth = :to_s)
    context "with #{format.to_s.upcase}" do
      should "have total downloads for version1" do
        get_show(@version1, format)
        assert_equal 3, yield(@response.body)['total_downloads'.send(to_meth)]
      end

      should "have downloads for the most recent version of version1" do
        get_show(@version1, format)
        assert_equal 1, yield(@response.body)['version_downloads'.send(to_meth)]
      end

      should "have total downloads for version2" do
        get_show(@version2, format)
        assert_equal 3, yield(@response.body)['total_downloads'.send(to_meth)]
      end

      should "have downloads for the most recent version of version2" do
        get_show(@version2, format)
        assert_equal 2, yield(@response.body)['version_downloads'.send(to_meth)]
      end
    end
  end

  context "on GET to show" do
    setup do
      rubygem = create(:rubygem)
      @version1 = create(:version, rubygem: rubygem, number: '1.0.0')
      @version2 = create(:version, rubygem: rubygem, number: '2.0.0')

      Download.incr(rubygem.name, @version1.full_name)
      Download.incr(rubygem.name, @version2.full_name)
      Download.incr(rubygem.name, @version2.full_name)
    end

    should_respond_to(:json) do |body|
      MultiJson.load body
    end

    should_respond_to(:yaml, :to_sym) do |body|
      YAML.load(body)
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get :show, id: "rials", format: 'json'
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

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      setup do
        get :top, format: format
      end

      should "have correct size" do
        assert_equal 3, yield(@response.body).size
      end

      should "have versions as hashes" do
        yield(@response.body).each do |arr|
          assert arr[0].is_a?(Hash)
        end
      end

      should "have correct version counts" do
        arr = yield(@response.body)
        assert_equal 3, arr[0][1]
        assert_equal 2, arr[1][1]
        assert_equal 1, arr[2][1]
      end
    end
  end

  context "On GET to top" do
    setup do
      @rubygem_1 = create(:rubygem)
      @version_1 = create(:version, rubygem: @rubygem_1)
      @version_2 = create(:version, rubygem: @rubygem_1)

      @rubygem_2 = create(:rubygem)
      @version_3 = create(:version, rubygem: @rubygem_2)

      @rubygem_3 = create(:rubygem)
      @version_4 = create(:version, rubygem: @rubygem_3)

      3.times { Download.incr(@rubygem_1.name, @version_1.full_name) }
      2.times { Download.incr(@rubygem_1.name, @version_2.full_name) }
      Download.incr(@rubygem_2.name, @version_3.full_name)

      Download.stubs(:most_downloaded_today).with(50).returns [[@version_1, 3],
                                                               [@version_2, 2],
                                                               [@version_3, 1]]
    end

    should_respond_to(:json) do |body|
      MultiJson.load(body)['gems']
    end

    should_respond_to(:yaml) do |body|
      YAML.load(body)[:gems]
    end
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

      3.times { Download.incr(@rubygem_1.name, @version_1.full_name) }
      2.times { Download.incr(@rubygem_1.name, @version_2.full_name) }
      Download.incr(@rubygem_2.name, @version_3.full_name)

      Download.stubs(:most_downloaded_all_time).with(50).returns([[@version_1, 3],
                                                                  [@version_2, 2],
                                                                  [@version_3, 1]])
    end

    should_respond_to(:json) do |body|
      MultiJson.load(body)['gems']
    end

    should_respond_to(:yaml) do |body|
      YAML.load(body)[:gems]
    end
  end
end
