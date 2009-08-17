ActionController::Routing::Routes.draw do |map|

  map.json_gem "/gems/:id.json",
    :controller   => "rubygems",
    :action       => "show",
    :format       => "json",
    :requirements => { :id => /.*/ }

  map.resource :migrate,
               :only         => [:create, :update],
               :controller   => "migrations",
               :path_prefix  => "/gems/:rubygem_id",
               :requirements => { :rubygem_id => /.*/ }

  map.resources :rubygems,
                :as           => "gems",
                :collection   => { :mine => :get },
                :requirements => { :id => /.*/ }

  map.search "/search", :controller => "searches", :action => "new"
  map.resource :api_key, :only => :show

  map.sign_up  'sign_up', :controller => 'clearance/users',    :action => 'new'
  map.sign_in  'sign_in', :controller => 'clearance/sessions', :action => 'new'
  map.sign_out 'sign_out',
    :controller => 'clearance/sessions',
    :action     => 'destroy',
    :method     => :delete

  map.root :controller => "home", :action => "index"
end
