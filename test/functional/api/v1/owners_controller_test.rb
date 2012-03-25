require 'test_helper'

class Api::V1::OwnersControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    should "route GET show with #{format.to_s.upcase}" do
      route = {:controller => 'api/v1/owners',
               :action     => 'show',
               :rubygem_id => "rails",
               :format     => format.to_s}
      assert_recognizes(route, "/api/v1/gems/rails/owners.#{format}")
    end

    context "on GET to show with #{format.to_s.upcase}" do
      setup do
        @rubygem = FactoryGirl.create(:rubygem)
        @user = FactoryGirl.create(:user)
        @rubygem.ownerships.create(:user => @user)

        @request.env["HTTP_AUTHORIZATION"] = @user.api_key
        get :show, :rubygem_id => @rubygem.to_param, :format => format
      end

      should "return an array" do
        response = yield(@response.body)
        assert_kind_of Array, response
      end

      should "return correct owner email" do
        assert_equal @user.email, yield(@response.body)[0]['email']
      end
    end
  end

  should_respond_to :xml do |body|
    Hash.from_xml(Nokogiri.parse(body).to_xml)['users']
  end

  should_respond_to :json do |body|
    MultiJson.decode body
  end

  should_respond_to :yaml do |body|
    YAML.load body
  end

  should "route POST" do
    route = {:controller => 'api/v1/owners',
             :action     => 'create',
             :rubygem_id => "rails",
             :format     => "json"}
    assert_recognizes(route, :path => '/api/v1/gems/rails/owners.json', :method => :post)
  end

  should "route DELETE" do
    route = {:controller => 'api/v1/owners',
             :action     => 'destroy',
             :rubygem_id => "rails",
             :format     => "json"}
    assert_recognizes(route, :path => '/api/v1/gems/rails/owners.json', :method => :delete)
  end

  should "route GET gems" do
    route = {:controller => 'api/v1/owners',
             :action      => 'gems',
             :handle      => 'example',
             :format      => 'json'}
    assert_recognizes(route, :path => '/api/v1/owners/example/gems.json', :method => :get)
  end
end
