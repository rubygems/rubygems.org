require 'test_helper'

class Api::V1::Versions::DownloadsControllerTest < ActionController::TestCase
  def get_index(version, format = 'json')
    get :index, version_id: version.full_name, format: format
  end

  def get_search(version, from, to, format = 'json')
    get :search, version_id: version.full_name,
                 format: format,
                 from: from.to_date.to_s,
                 to: to.to_date.to_s
  end


  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      should "have 90 attributes, one per day of gem version download counts" do
        get_index(@version, format)
        assert_equal 90, yield(@response.body).size
      end

      should "have an object with the download counts by day" do
        get_index(@version, format)
        hash = yield(@response.body)
        assert_equal 42, hash[@eight_nine_days_ago]
        assert_equal 2, hash[@one_day_ago]
        assert_equal 1, hash[Time.zone.today.to_s]
      end
    end
  end

  context "on GET to index" do
    setup do
      @version = create(:version)
      @eight_nine_days_ago = 89.days.ago.to_date.to_s
      @one_day_ago = 1.day.ago.to_date.to_s

      Redis.current.hincrby Download.history_key(@version), @eight_nine_days_ago, 42
      Redis.current.hincrby Download.history_key(@version), @one_day_ago, 2
      Download.incr(@version.rubygem.name, @version.full_name)
    end

    should_respond_to(:json) do |body|
      MultiJson.load body
    end

    should_respond_to(:yaml) do |body|
      YAML.load body
    end

  end

  context "on GET to index for an unknown gem" do
    setup do
      get :index, version_id: "nonexistent_gem", format: 'json'
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end

  context "on GET to index for a yanked gem" do
    setup do
      version = create(:version, indexed: false)
      get_index(version)
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end

  context "on GET to search for a yanked gem" do
    setup do
      version = create(:version, indexed: false)
      get_search(version, 2.days.ago, 1.day.ago)
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end

  context "on GET to search with missing params" do
    setup do
      version = create(:version, indexed: false)
      get :search, version_id: version.full_name, format: 'json'
    end

    should respond_with :bad_request
    should "explain failed request" do
      assert page.has_content?("Request is missing param 'from'")
    end
  end

  def self.should_respond_to(format)
    context "with #{format.to_s.upcase}" do
      should "return download stats for the days specified for at most 90 days" do
        get_search(@version, @one_hundred_eighty_nine_days_ago, @one_hundred_days_ago, format)
        hash = yield(@response.body)

        assert_equal 90, hash.size
        assert_equal 42, hash[@one_hundred_eighty_nine_days_ago]
        assert_equal 1764, hash[@one_hundred_days_ago]
        assert_nil hash[@one_hundred_ninety_days_ago]
      end

      should "return download stats for the days specified for ranges smaller than 90 days" do
        get_search(@version, @one_hundred_one_days_ago, @one_hundred_days_ago, format)
        hash = yield(@response.body)

        assert_equal 2, hash.size
        assert_equal 0, hash[@one_hundred_one_days_ago]
        assert_equal 1764, hash[@one_hundred_days_ago]
      end

      should "be able to return stats for a single day" do
        get_search(@version, @one_hundred_days_ago, @one_hundred_days_ago, format)
        hash = yield(@response.body)

        assert_equal 1, hash.size
        assert_equal 1764, hash[@one_hundred_days_ago]
      end
    end
  end

  context "on GET to search" do
    setup do
      @one_hundred_days_ago = 100.days.ago.to_date.to_s
      @one_hundred_one_days_ago = 101.days.ago.to_date.to_s
      @one_hundred_eighty_nine_days_ago = 189.day.ago.to_date.to_s
      @one_hundred_ninety_days_ago = 190.day.ago.to_date.to_s
    end

    context "happy path" do
      setup do
        @version = create(:version)

        Redis.current.hincrby Download.history_key(@version), @one_hundred_ninety_days_ago, 41
        Redis.current.hincrby Download.history_key(@version), @one_hundred_eighty_nine_days_ago, 42
        Redis.current.hincrby Download.history_key(@version), @one_hundred_days_ago, 1764
      end

      should_respond_to(:json) do |body|
        MultiJson.load body
      end

      should_respond_to(:yaml) do |body|
        YAML.load body
      end
    end

    context "for an unknown gem" do
      setup do
        get :index, version_id: "nonexistent_gem",
                    format: 'json',
                    from: @one_hundred_days_ago,
                    to: @one_hundred_eighty_nine_days_ago
      end

      should "return a 404" do
        assert_response :not_found
      end

      should "say gem could not be found" do
        assert_equal "This rubygem could not be found.", @response.body
      end
    end
  end
end
