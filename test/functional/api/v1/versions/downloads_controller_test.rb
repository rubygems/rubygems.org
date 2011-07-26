require 'test_helper'

class Api::V1::Versions::DownloadsControllerTest < ActionController::TestCase
  def get_index(version, format='json')
    get :index, :version_id => version.full_name, :format => format
  end

  def get_search(version, from, to, format='json')
    get :search, :version_id => version.full_name,
                 :format => format,
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


    context "with JSON" do
      should "have a JSON object with 90 attributes, one per day of gem version download counts" do
        get_index(@version)
        assert_equal 90, JSON.parse(@response.body).count
      end

      should "have a JSON object with the download counts by day" do
        get_index(@version)
        json = JSON.parse(@response.body)
        assert_equal 42, json[@eight_nine_days_ago]
        assert_equal 2, json[@one_day_ago]
        assert_equal 1, json[Time.zone.today.to_s]
      end
    end

    context "with YAML" do
      should "have a YAML object with 90 attributes, one per day of gem version download counts" do
        get_index(@version, 'yaml')
        assert_equal 90, YAML.load(@response.body).count
      end

      should "have a JSON object with the download counts by day" do
        get_index(@version, 'yaml')
        yaml = YAML.load(@response.body)
        assert_equal 42, yaml[@eight_nine_days_ago]
        assert_equal 2, yaml[@one_day_ago]
        assert_equal 1, yaml[Time.zone.today.to_s]
      end
    end

  end

  context "on GET to index for an unknown gem" do
    setup do
      get :index, :version_id => "nonexistent_gem", :format => 'json'
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
      version = Factory(:version, :indexed => false)
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
      version = Factory(:version, :indexed => false)
      get_search(version, 2.days.ago, 1.day.ago)
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
                    :format => 'json',
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
