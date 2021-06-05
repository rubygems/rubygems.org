require "test_helper"

class Api::V1::SearchesControllerTest < ActionController::TestCase
  include ESHelper

  def self.should_respond_to(format)
    context "with query=match and with #{format.to_s.upcase}" do
      setup do
        get :show, params: { query: "match" }, format: format
      end

      should respond_with :success
      should "contain a hash" do
        assert_kind_of Hash, yield(@response.body).first
      end
      should "only include matching gems" do
        gems = yield(@response.body)
        assert_equal 1, gems.size
        assert_equal "match", gems.first["name"]
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
      import_and_refresh
    end

    should_respond_to(:json) do |body|
      JSON.parse(body)
    end

    should_respond_to(:yaml) do |body|
      YAML.safe_load body
    end

    context "with elasticsearch down" do
      should "fallback to legacy search" do
        requires_toxiproxy
        Toxiproxy[:elasticsearch].down do
          get :show, params: { query: "other" }, format: :json
          assert_response :success
          assert_equal "other", JSON.parse(@response.body).first["name"]
        end
      end
    end
  end

  context "on GET to autocomplete with query=ma" do
    setup do
      @match1 = create(:rubygem, name: "match1")
      @match2 = create(:rubygem, name: "match2")
      @other = create(:rubygem, name: "other")
      create(:version, rubygem: @match1)
      create(:version, rubygem: @match2)
      create(:version, rubygem: @other)
      import_and_refresh
    end

    context "with elasticsearch up" do
      setup do
        get :autocomplete, params: { query: "ma" }
        @body = JSON.parse(response.body)
      end

      should respond_with :success
      should "return gems name" do
        assert_equal 2, @body.size
        assert_equal "match1", @body[0]
      end
      should "not contain other gems" do
        assert_not @body.include?("other")
      end
    end

    context "with elasticsearch down" do
      should "fallback to legacy search" do
        requires_toxiproxy
        Toxiproxy[:elasticsearch].down do
          get :autocomplete, params: { query: "ot" }
          assert_response :success
          assert_empty JSON.parse(@response.body)
        end
      end
    end
  end
end
