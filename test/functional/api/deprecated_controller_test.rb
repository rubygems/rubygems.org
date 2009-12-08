require 'test_helper'

class Api::DeprecatedControllerTest < ActionController::TestCase

  should "route old paths to new controller" do
    route = { :controller => "api/deprecated" }
    assert_recognizes(route.merge(:action => "show"),  :path => "/api_key")
    assert_recognizes(route.merge(:action => "reset"), :path => "/api_key/reset", :method => :put)

    route = { :controller => "api/deprecated", :rubygem_id => "rails", :format => "json" }
    assert_recognizes(route.merge(:action => "show"),    :path => "/gems/rails/owners.json")
    assert_recognizes(route.merge(:action => "create"),  :path => "/gems/rails/owners.json", :method => :post)
    assert_recognizes(route.merge(:action => "destroy"), :path => "/gems/rails/owners.json", :method => :delete)

    route = { :controller => "api/deprecated", :id => "rails", :format => "json" }
    assert_recognizes(route.merge(:action => "index"), :path => "/gems/rails.json")

    route = { :controller => "api/deprecated" }
    assert_recognizes(route.merge(:action => "create"), :path => '/gems', :method => :post)
  end

end
