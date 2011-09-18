RubygemsOrg::Application.routes.draw do
  ################################################################################
  # API v1

  namespace :api do
    namespace :v1 do
      resource :api_key, :only => :show do
        put :reset
      end
      resources :downloads, :only => :index do
        get :top, :on => :collection
        get :all, :on => :collection
      end
      constraints :id => Patterns::ROUTE_PATTERN, :format => /json|xml|yaml/ do
        # In Rails 3.1, the following line can be replaced with:
        # resources :downloads, :only => :show, :format => true
        get 'downloads/:id.:format', :to => 'downloads#show', :as => 'download'
        # In Rails 3.1, the next TWO lines can be replaced with:
        # resources :versions, :only => :show, :format => true do
        get 'versions/:id.:format', :to => 'versions#show', :as => 'version'
        resources :versions, :only => :show do
          # In Rails 3.1, the next TWO lines can be replaced with:
          # resources :downloads, :only => :show, :controller => 'versions/downloads', :format => true do
          get 'downloads.:format', :to => 'versions/downloads#index', :as => 'downloads'
          resources :downloads, :only => :index, :controller => 'versions/downloads' do
            collection do
              # In Rails 3.1, the following line can be replaced with:
              # get :search, :format => true
              get 'search.:format', :to => 'versions/downloads#search', :as => 'search'
            end
          end
        end
      end

      resources :dependencies, :only => :index

      resources :rubygems, :path => 'gems', :only => [:create, :show, :index], :id => Patterns::LAZY_ROUTE_PATTERN, :format => /json|xml|yaml/ do
        collection do
          delete :yank
          put :unyank
          get :latest
          get :just_updated
        end
        constraints :rubygem_id => Patterns::ROUTE_PATTERN do
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

  scope :to => 'api/deprecated#index' do
    get 'api_key'
    put 'api_key/reset'

    post 'gems'
    get  'gems/:id.json'

    scope :path => 'gems/:rubygem_id' do
      put  'migrate'
      post 'migrate'
      get    'owners(.:format)'
      post   'owners(.:format)'
      delete 'owners(.:format)'
    end
  end

  ################################################################################
  # UI

  resource  :search,    :only => :show
  resource  :dashboard, :only => :show
  resources :profiles,  :only => :show
  resource  :profile,   :only => [:edit, :update]
  resources :stats,     :only => :index

  resources :rubygems, :only => :index, :path => 'gems' do
    constraints :rubygem_id => Patterns::ROUTE_PATTERN do
      resource  :subscription, :only => [:create, :destroy]
      resources :versions,     :only => :index
      resource  :stats,        :only => :show
    end
  end

  constraints :id => Patterns::ROUTE_PATTERN do
    resources :rubygems, :path => 'gems', :only => [:show, :edit, :update] do

      constraints :rubygem_id => Patterns::ROUTE_PATTERN do
        resources :versions, :only => :show do
          resource :stats, :only => :show
        end
      end
    end
  end

  ################################################################################
  # Clearance Overrides

  resource :session, :only => [:new, :create]

  resources :passwords, :only => [:new, :create]

  resources :users do
    resource :password, :only => [:create, :edit, :update]
  end

  ################################################################################
  # Root

  root :to => 'home#index'

end
