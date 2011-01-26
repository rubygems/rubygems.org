RUBYGEM_NAME_MATCHER = /[A-Za-z0-9\-\_\.]+/

Gemcutter::Application.routes.draw do

  ################################################################################
  # API v1

  namespace :api do
    namespace :v1 do
      resource :api_key, :only => :show do
        put :reset
      end

      resources :downloads, :only => :index
      constraints :id => RUBYGEM_NAME_MATCHER do
        resources :downloads, :only => :show
      end

      resources :dependencies, :only => :index

      resources :rubygems, :path => "gems", :only => [:create, :show, :index] do
        collection do
          delete :yank
          put :unyank
        end
        constraints :rubygem_id => RUBYGEM_NAME_MATCHER do
          resource :owners, :only => [:show, :create, :destroy]
        end
      end

      resource :search, :only => :show

      resources :web_hooks, :only => [:create, :index] do
        collection do
          delete :remove
          post :fire
        end
      end
    end
  end

  ################################################################################
  # API v0

  scope :to => "api/deprecated#index" do
    get "api_key"
    put "api_key/reset"

    post "gems"
    get  "gems/:id.json"

    scope :path => "gems/:rubygem_id" do
      put  "migrate"
      post "migrate"
      get    "owners(.:format)"
      post   "owners(.:format)"
      delete "owners(.:format)"
    end
  end

  ################################################################################
  # UI

  resource  :search,    :only => :show
  resource  :dashboard, :only => :show
  resources :profiles,  :only => :show
  resource  :profile,   :only => [:edit, :update]
  resources :stats,     :only => :index

  resources :rubygems, :only => :index, :path => "gems" do
    constraints :rubygem_id => RUBYGEM_NAME_MATCHER do
      resource  :subscription, :only => [:create, :destroy]
      resources :versions,     :only => :index
      resource  :stats,        :only => :show
    end
  end

  constraints :id => RUBYGEM_NAME_MATCHER do
    resources :rubygems, :path => "gems", :only => [:show, :edit, :update] do

      constraints :rubygem_id => RUBYGEM_NAME_MATCHER do
        resources :versions, :only => :show do
          resource :stats, :only => :show
        end
      end
    end
  end

  ################################################################################
  # Clearance Overrides

  resource :session, :only => [:new, :create]
  scope :path => "users/:user_id" do
    resource :confirmation, :only => [:new, :create], :as => :user_confirmation
  end

  resources :passwords, :only => [:new, :create]

  resources :users do
    resource :password, :only => [:create, :edit, :update]
    resource :confirmation, :only => [:new, :create]
  end

  ################################################################################
  # Root

  root :to => "home#index"

end
