require 'test_helper'

class Api::V1::SearchesControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    context "and with #{format.to_s.upcase}" do
      setup do
        get :show, :query => "match", :format => format
      end
      should respond_with :success
      should "return a hash" do
        assert Hash, yield(@response.body).class
      end
      should "only include matching gems" do
        gems = yield(@response.body)
        assert_equal 1, gems.size
        assert_equal "match", gems.first['name']
      end
    end
  end

  context "on GET to show with query=match" do
    setup do
      @match = Factory(:rubygem, :name => "match")
      @other = Factory(:rubygem, :name => "other")
      Factory(:version, :rubygem => @match)
      Factory(:version, :rubygem => @other)
    end

    should_respond_to(:json) do |body|
      JSON.parse body
    end

    should_respond_to(:xml) do |body|
      Hash.from_xml(Nokogiri.parse(body).to_xml)['rubygems']
    end

    should_respond_to(:yaml) do |body|
      YAML.load body
    end
  end
end
