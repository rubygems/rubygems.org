RUBYGEM_NAME_MATCHER = /[A-Za-z0-9\-\_\.]+/

ActionController::Routing::Routes.draw do |map|

  ################################################################################
  # API v1

  map.namespace :api do |api|
    api.namespace :v1 do |v1|
      v1.resource  :api_key,
                   :only         => [:show, :reset],
                   :member       => {:reset => :put}
      v1.json_gem  "/gems/:id.json",
                   :controller   => "rubygems",
                   :action       => "show",
                   :format       => "json",
                   :requirements => { :id => RUBYGEM_NAME_MATCHER }
      v1.resources :rubygems,
                   :as           => "gems",
                   :only         => [:create] do |rubygems|

        rubygems.resource :owners,
          :only       => [:show, :create, :destroy]
      end
      v1.resources :web_hooks,
                   :only => [:create]
    end
  end

  ################################################################################
  # API v0

  map.json_gem "/gems/:id.json",
               :controller   => "api/v1/rubygems",
               :action       => "show",
               :format       => "json",
               :requirements => { :id => RUBYGEM_NAME_MATCHER }
  map.resource :api_key,
               :only         => [:show, :reset],
               :member       => {:reset => :put},
               :controller   => "api/v1/api_keys"
  map.resource :migrate,
               :only         => [:create, :update],
               :controller   => "migrations",
               :path_prefix  => "/gems/:rubygem_id",
               :requirements => { :rubygem_id => RUBYGEM_NAME_MATCHER }

  ################################################################################
  # UI

  map.search "/search", :controller => "searches", :action => "new"
  map.resource  :dashboard,  :only => :show
  map.resource  :profile
  map.resources :statistics, :only => :index, :as => "stats"

  map.resources :rubygems,
                :as           => "gems",
                :except       => [:create],
                :requirements => { :id => RUBYGEM_NAME_MATCHER } do |rubygems|

    rubygems.resource :owners,
      :only       => [:show, :create, :destroy],
      :controller => 'api/v1/owners'

    rubygems.resource :subscription, :only => [:create, :destroy]

    rubygems.resources :versions,
      :only         => [:index, :show],
      :requirements => { :rubygem_id => RUBYGEM_NAME_MATCHER, :id => RUBYGEM_NAME_MATCHER }
  end

  map.resources :rubygems,
                :as         => "gems",
                :controller => "api/v1/rubygems",
                :only       => [:create]

  ################################################################################
  # Clearance

  map.sign_up  'sign_up', :controller => 'clearance/users',    :action => 'new'
  map.sign_in  'sign_in', :controller => 'clearance/sessions', :action => 'new'
  map.sign_out 'sign_out',
    :controller => 'clearance/sessions',
    :action     => 'destroy',
    :method     => :delete

  ################################################################################
  # Root

  map.root :controller => "home", :action => "index"

end
