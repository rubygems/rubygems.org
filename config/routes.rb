RUBYGEM_NAME_MATCHER = /[A-Za-z0-9\-\_\.]+/

ActionController::Routing::Routes.draw do |map|

  map.json_gem "/gems/:id.json",
    :controller   => "rubygems",
    :action       => "show",
    :format       => "json",
    :requirements => { :id => RUBYGEM_NAME_MATCHER }

  map.resource :dashboard, :only => :show

  map.resource :migrate,
               :only         => [:create, :update],
               :controller   => "migrations",
               :path_prefix  => "/gems/:rubygem_id",
               :requirements => { :rubygem_id => RUBYGEM_NAME_MATCHER }

  map.resources :rubygems,
                :as           => "gems",
                :requirements => { :id => RUBYGEM_NAME_MATCHER } do |rubygems|

    rubygems.resource :owners, :only => [:show, :create, :destroy]

    rubygems.resource :subscription, :only => [:create, :destroy]

    rubygems.resources :versions,
      :only         => [:index, :show],
      :requirements => { :rubygem_id => RUBYGEM_NAME_MATCHER, :id => Gem::Version::VERSION_PATTERN }
  end

  map.search "/search", :controller => "searches", :action => "new"
  map.resource :api_key, :only => :show

  map.sign_up  'sign_up', :controller => 'clearance/users',    :action => 'new'
  map.sign_in  'sign_in', :controller => 'clearance/sessions', :action => 'new'
  map.sign_out 'sign_out',
    :controller => 'clearance/sessions',
    :action     => 'destroy',
    :method     => :delete

  map.resource :session, :only => [:new, :create, :destroy]

  map.root :controller => "home", :action => "index"
end
