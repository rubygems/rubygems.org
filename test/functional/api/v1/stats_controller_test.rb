require 'test_helper'

class Api::V1::StatsControllerTest < ActionController::TestCase
  def get_show(version)
    get :show, :id => "#{version.full_name}.json"
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
      assert_equal 1, json[Date.today.to_s]
    end
  end

  context "on GET to show for an unknown gem" do
    setup do
      get :show, :id => "nonexistent_gem"
    end

    should "return a 404" do
      assert_response :not_found
    end

    should "say gem could not be found" do
      assert_equal "This rubygem could not be found.", @response.body
    end
  end
end
