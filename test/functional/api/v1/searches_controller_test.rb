require 'test_helper'

class Api::V1::SearchesControllerTest < ActionController::TestCase

  context "On GET to show with query=match" do
    setup do
      @match = Factory(:rubygem, :name => "match")
      @other = Factory(:rubygem, :name => "other")
      Factory(:version, :rubygem => @match)
      Factory(:version, :rubygem => @other)

      get :show, :query => "match"
    end

    should_respond_with :success
    should "return a json hash" do
      assert_not_nil JSON.parse(@response.body)
    end
    should "only include matching gems" do
      gems = JSON.parse(@response.body).map { |g| g["name"] }
      assert_contains         gems, "match"
      assert_does_not_contain gems, "other"
    end
  end

end
