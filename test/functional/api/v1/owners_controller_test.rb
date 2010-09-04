require_relative '../../../test_helper'

class Api::V1::OwnersControllerTest < ActionController::TestCase
  should "route GET to new controller" do
    route = {:controller => 'api/v1/owners',
             :action     => 'show',
             :rubygem_id => "rails",
             :format     => "json"}
    assert_recognizes(route, '/api/v1/gems/rails/owners.json')
  end

  should "route POST to new controller" do
    route = {:controller => 'api/v1/owners',
             :action     => 'create',
             :rubygem_id => "rails",
             :format     => "json"}
    assert_recognizes(route, :path => '/api/v1/gems/rails/owners.json', :method => :post)
  end

  should "route DELETE to new controller" do
    route = {:controller => 'api/v1/owners',
             :action     => 'destroy',
             :rubygem_id => "rails",
             :format     => "json"}
    assert_recognizes(route, :path => '/api/v1/gems/rails/owners.json', :method => :delete)
  end
end
