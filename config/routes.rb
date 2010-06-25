RUBYGEM_NAME_MATCHER = /[A-Za-z0-9\-\_\.]+/

ActionController::Routing::Routes.draw do |map|

  ################################################################################
  # API v1

  map.namespace :api do |api|
    api.namespace :v1 do |v1|
      v1.resource  :api_key,
                   :only         => [:show, :reset],
                   :member       => {:reset => :put}
      v1.resources :rubygems,
                   :as           => "gems",
                   :collection   => {:yank => :delete, :unyank => :put},
                   :only         => [:create, :show] do |rubygems|
        rubygems.resource :owners,
          :only       => [:show, :create, :destroy]
      end
      v1.resource  :search, :only => :show
      v1.resources :web_hooks,
                   :only       => [:create, :index],
                   :collection => {:remove => :delete,
                                   :fire   => :post}
      v1.resources :downloads, :only => :index
    end
  end

  ################################################################################
  # API v0

  map.json_gem "/gems/:id.json",
               :controller   => "api/deprecated",
               :format       => "json",
               :requirements => { :id => RUBYGEM_NAME_MATCHER }
  map.resource :api_key,
               :only         => [:show, :reset],
               :member       => {:reset => :put},
               :controller   => "api/deprecated"
  map.resource :migrate,
               :only         => [:create, :update],
               :controller   => "api/deprecated",
               :path_prefix  => "/gems/:rubygem_id",
               :requirements => { :rubygem_id => RUBYGEM_NAME_MATCHER }

  ################################################################################
  # UI

  map.search "/search", :controller => "searches", :action => "new"
  map.resource  :dashboard,  :only => :show
  map.resource  :profile,    :only => [:edit, :update]
  map.resources :statistics, :only => :index, :as => "stats"

  map.resources :rubygems,
                :as           => "gems",
                :except       => [:create],
                :requirements => { :id => RUBYGEM_NAME_MATCHER } do |rubygems|

    rubygems.resource :owners,
      :only       => [:show, :create, :destroy],
      :controller => "api/deprecated"

    rubygems.resource :subscription, :only => [:create, :destroy]

    rubygems.resources :versions,
      :only         => [:index, :show],
      :requirements => { :rubygem_id => RUBYGEM_NAME_MATCHER, :id => RUBYGEM_NAME_MATCHER }
  end

  map.resources :rubygems,
                :as         => "gems",
                :controller => "api/deprecated",
                :only       => [:create]

  ################################################################################
  # Clearance

  map.sign_up  'sign_up', :controller => 'clearance/users',    :action => 'new'
  map.sign_in  'sign_in', :controller => 'clearance/sessions', :action => 'new'
  map.sign_out 'sign_out',
    :controller => 'clearance/sessions',
    :action     => 'destroy',
    :method     => :delete
  map.resource  :session,
    :controller => 'sessions',
    :only       => :create
  map.resources :users, :controller => 'clearance/users' do |users|
    users.resource :confirmation,
      :controller => 'confirmations',
      :only       => [:new, :create]
  end

  ################################################################################
  # Root

  map.root :controller => "home", :action => "index"

end
