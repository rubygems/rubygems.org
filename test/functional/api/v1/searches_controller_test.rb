require 'test_helper'

class Api::V1::SearchesControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    context "with query=match and with #{format.to_s.upcase}" do
      setup do
        get :show, :query => "match", :format => format
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
        get :show, :format => format
      end

      should respond_with :bad_request
      should "explain failed request" do
        assert page.has_content?("Request is missing param :query")
      end
    end
  end

  context "on GET to show" do
    setup do
      @match = Factory(:rubygem, :name => "match")
      @other = Factory(:rubygem, :name => "other")
      Factory(:version, :rubygem => @match)
      Factory(:version, :rubygem => @other)
    end

    should_respond_to(:json) do |body|
      Yajl.load body
    end

    should_respond_to(:xml) do |body|
      Hash.from_xml(Nokogiri.parse(body).to_xml)['rubygems']
    end

    should_respond_to(:yaml) do |body|
      YAML.load body
    end
  end
end
