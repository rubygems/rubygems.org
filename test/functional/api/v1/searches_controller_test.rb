require 'test_helper'
require 'yaml'

class Api::V1::SearchesControllerTest < ActionController::TestCase
  context "with some gems" do
    setup do
      @match = Factory(:rubygem, :name => "match")
      @other = Factory(:rubygem, :name => "other")
      Factory(:version, :rubygem => @match)
      Factory(:version, :rubygem => @other)
    end

    context "On GET to show with query=match for json" do
      setup do
        get :show, :query => "match", :format => "json"
      end
      should respond_with :success
      should "return a json hash" do
        assert_not_nil JSON.parse(@response.body)
      end
      should "only include matching gems" do
        gems = JSON.parse(@response.body).map { |g| g["name"] }
        assert_contains         gems, "match"
        assert_does_not_contain gems, "other"
      end
    end

    context "On GET to show with query=match for xml" do
      setup do
        get :show, :query => "match", :format => "xml"
      end
      should respond_with :success
      should "return xml" do
        assert_not_nil Nokogiri.parse(@response.body).root
      end
      should "only include matching gems" do
        gems = Nokogiri.parse(@response.body).css("name")
        assert_equal 1, gems.size
        assert_equal "match", gems.first.content
      end
    end

    context "On GET to show with query=match for yaml" do
      setup do
        get :show, :query => "match", :format => "yaml"
      end
      should respond_with :success
      should "return yaml" do
        assert_not_nil YAML.load(@response.body)
      end
      should "only include matching gems" do
        gems = YAML.load(@response.body)
        assert_equal 1, gems.size
        assert_equal "match", gems.first['name']
      end
    end
  end
end
