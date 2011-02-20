require 'test_helper'

class Api::V1::Versions::DownloadsControllerTest < ActionController::TestCase
  def get_show(version)
    get :index, :version_id => "#{version.full_name}.json"
  end

  def get_search(version, from, to)
    get :search, :version_id => "#{version.full_name}.json", 
                 :from => from.to_date.to_s,
                 :to => to.to_date.to_s
  end

  context "on GET to show" do
    setup do
      @version = Factory(:version)
      @eight_nine_days_ago = 89.days.ago.to_date.to_s
      @one_day_ago = 1.day.ago.to_date.to_s

      $redis.hincrby Download.history_key(@version), @eight_nine_days_ago, 42
      $redis.hincrby Download.history_key(@version), @one_day_ago, 2
      Download.incr(@version.rubygem.name, @version.full_name)
    end

    should "have a json object with 90 attributes, one per day of gem version download counts" do
      get_show(@version)
      assert_equal 90, JSON.parse(@response.body).count
    end

    should "have a json object with the download counts by day" do
      get_show(@version)
      json = JSON.parse(@response.body)
      assert_equal 42, json[@eight_nine_days_ago]
      assert_equal 2, json[@one_day_ago]
      assert_equal 1, json[Time.zone.today.to_s]
    end
  end

  context "on GET to index for an unknown gem" do
    setup do
      get :index, :version_id => "nonexistent_gem"
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
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
        @version = Factory(:version)

        $redis.hincrby Download.history_key(@version), @one_hundred_ninety_days_ago, 41
        $redis.hincrby Download.history_key(@version), @one_hundred_eighty_nine_days_ago, 42
        $redis.hincrby Download.history_key(@version), @one_hundred_days_ago, 1764
      end

      should "return download stats for the days specified for at most 90 days" do
        get_search(@version, @one_hundred_eighty_nine_days_ago, @one_hundred_days_ago)
        json = JSON.parse(@response.body)

        assert_equal 90, json.size
        assert_equal 42, json[@one_hundred_eighty_nine_days_ago]
        assert_equal 1764, json[@one_hundred_days_ago]
        assert_nil json[@one_hundred_ninety_days_ago]
      end

      should "return download stats for the days specified for ranges smaller than 90 days" do
        get_search(@version, @one_hundred_one_days_ago, @one_hundred_days_ago)
        json = JSON.parse(@response.body)

        assert_equal 2, json.size
        assert_equal 0, json[@one_hundred_one_days_ago]
        assert_equal 1764, json[@one_hundred_days_ago]
      end

      should "be able to return stats for a single day" do
        get_search(@version, @one_hundred_days_ago, @one_hundred_days_ago)
        json = JSON.parse(@response.body)

        assert_equal 1, json.size
        assert_equal 1764, json[@one_hundred_days_ago]
      end
    end

    context "for an unknown gem" do
      setup do
        get :index, :version_id => "nonexistent_gem", 
                    :from => @one_hundred_days_ago,
                    :to => @one_hundred_eighty_nine_days_ago
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
