require "test_helper"

class Api::V1::TimeframeVersionsControllerTest < ActionController::TestCase
  setup do
    @rails = create(:rubygem, name: "rails")
    @rails_version1 = create(:version, rubygem: @rails, created_at: Time.zone.parse("2017-10-10"))
    @rails_version2 = create(:version, rubygem: @rails, created_at: Time.zone.parse("2017-11-10"))

    @sinatra = create(:rubygem, name: "sinatra")
    @sinatra_version = create(:version, rubygem: @sinatra, created_at: Time.zone.parse("2017-11-11"))
  end

  context "GET to index" do
    context "with valid timeframe params" do
      should "return the versions created within the timeframe" do
        get :index, format: :json, params: {
          from: Time.parse("2017-11-09").iso8601,
          to: Time.parse("2017-11-12").iso8601
        }

        gems = JSON.parse @response.body
        assert_equal 2, gems.length
        assert_equal "rails", gems[0]["name"]
        assert_equal @rails_version2.number, gems[0]["version"]
        assert_equal Time.zone.iso8601("2017-11-10"), gems[0]["created_at"]
        assert_equal "sinatra", gems[1]["name"]
        assert_equal Time.zone.iso8601("2017-11-11"), gems[1]["created_at"]
      end

      should "allow paging through results" do
        get :index, format: :json, params: {
          from: Time.zone.parse("2017-11-09").iso8601,
          to: Time.parse("2017-11-12").iso8601,
          page: 2
        }

        gems = JSON.parse @response.body
        assert_empty gems
      end
    end

    context "with invalid timeframe params" do
      should 'return a bad request with message when "to" is invalid' do
        get :index, format: :json, params: {
          from: Time.zone.parse("2017-11-09").iso8601,
          to: "2017-11-12"
        }

        assert_equal 400, response.status
        assert_includes response.body, "iso8601"
      end

      should 'return a bad request with message when "from" is invalid' do
        get :index, format: :json, params: {
          from: "2017-11-09",
          to: Time.zone.parse("2017-11-12").iso8601
        }

        assert_equal 400, response.status
        assert_includes response.body, "iso8601"
      end

      should "return a bad request with message when the range exceeds the max allowed" do
        get :index, format: :json, params: {
          from: Time.zone.parse("2017-11-09").iso8601,
          to: Time.zone.parse("2017-11-30").iso8601
        }

        assert_equal 400, response.status
        assert_includes response.body, "query time range cannot exceed"
      end

      should "return a bad request with message if from is after to" do
        get :index, format: :json, params: {
          from: Time.zone.parse("2017-11-11").iso8601,
          to: Time.zone.parse("2017-11-09").iso8601
        }

        assert_equal 400, response.status
        assert_includes response.body, "must be before the ending time parameter"
      end
    end

    context "with missing params" do
      should 'return a bad request when "from" is missing' do
        get :index, format: :json, params: { to: Time.zone.parse("2017-11-12").iso8601 }

        assert_equal 400, response.status
        assert_includes response.body, "missing"
      end

      should 'default to the current time if "to" is missing' do
        @sinatra_version.created_at = Time.zone.now.advance(days: -3)
        @sinatra_version.save!
        get :index, format: :json, params: { from: Time.zone.now.advance(days: -5).iso8601 }
        gems = JSON.parse @response.body
        assert_equal 1, gems.length
        assert_equal "sinatra", gems[0]["name"]
      end
    end
  end
end
