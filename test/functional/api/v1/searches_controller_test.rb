require 'test_helper'

class Api::V1::SearchesControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    context "with query=match and with #{format.to_s.upcase}" do
      setup do
        get :show, query: "match", format: format
      end

      should respond_with :success
      should "contain a hash" do
        assert_kind_of Hash, yield(@response.body).first
      end
      should "only include matching gems" do
        gems = yield(@response.body)
        assert_equal 1, gems.size
        assert_equal "match", gems.first['name']
      end
    end

    context "with no query and with #{format.to_s.upcase}" do
      setup do
        get :show, format: format
      end

      should respond_with :bad_request
      should "explain failed request" do
        assert page.has_content?("Request is missing param 'query'")
      end
    end
  end

  context "on GET to show" do
    setup do
      @match = create(:rubygem, name: "match")
      @other = create(:rubygem, name: "other")
      create(:version, rubygem: @match)
      create(:version, rubygem: @other)
    end

    should_respond_to(:json) do |body|
      JSON.parse(body)
    end

    should_respond_to(:yaml) do |body|
      YAML.load body
    end
  end

  context "on GET passing a page" do
    setup do
      @match = create(:rubygem, name: "match")
      create(:version, rubygem: @match)
    end

    should "default to first page when page is 0" do
      get :show, query: "match", page: 0, format: :json
      refute JSON.parse(response.body).empty?
    end

    should "default to first page when page is not a number" do
      get :show, query: "match", page: "foo", format: :json
      refute JSON.parse(response.body).empty?
    end

    should "default to first page when page cannot be converted to a number" do
      get :show, query: "match", page: {}, format: :json
      refute JSON.parse(response.body).empty?
    end
  end
end
