Rails.application.routes.draw do
  ################################################################################
  # Root

  root to: 'home#index'

  ################################################################################
  # API

  namespace :api do
    namespace :v2 do
      resources :rubygems, param: :name, only: [], constraints: { name: Patterns::ROUTE_PATTERN } do
        resources :versions, param: :number, only: :show, constraints: {
          number: /#{Gem::Version::VERSION_PATTERN}(?=\.json\z)|#{Gem::Version::VERSION_PATTERN}/
        }
      end
    end

    namespace :v1 do
      resource :api_key, only: :show do
        put :reset
      end
      resources :profiles, only: :show
      resources :downloads, only: :index do
        get :top, on: :collection
        get :all, on: :collection
      end
      constraints id: Patterns::ROUTE_PATTERN, format: /json|yaml/ do
        get 'owners/:handle/gems',
          to: 'owners#gems',
          as: 'owners_gems',
          constraints: { handle: Patterns::ROUTE_PATTERN },
          format: true

        resources :downloads, only: :show, format: true

        resources :versions, only: :show, format: true do
          member do
            get :reverse_dependencies, format: true
            get 'latest',
              to: 'versions#latest',
              as: 'latest',
              format: true,
              constraints: { format: /json|js/ }
          end

          resources :downloads,
            only: [:index],
            controller: 'versions/downloads',
            format: true do
            collection do
              get :search, format: true
            end
          end
        end
      end

      resources :dependencies,
        only: [:index],
        format: /marshal|json/,
        defaults: { format: 'marshal' }

      # for handling preflight request
      match '/gems/:id' => "rubygems#show", via: :options

      resources :rubygems,
        path: 'gems',
        only: [:create, :show, :index],
        id: Patterns::LAZY_ROUTE_PATTERN,
        format: /json|yaml/ do
        member do
          get :reverse_dependencies
        end
        collection do
          delete :yank, to: "deletions#create"
          put :unyank, to: "deletions#destroy"
        end
        constraints rubygem_id: Patterns::ROUTE_PATTERN do
          resource :owners, only: [:show, :create, :destroy]
        end
      end

      resource :activity, only: [], format: /json|yaml/ do
        collection do
          get :latest
          get :just_updated
        end
      end

      resource :search, only: :show

      resources :web_hooks, only: [:create, :index] do
        collection do
          delete :remove
          post :fire
        end
      end
    end
  end

  get '/versions' => 'api/compact_index#versions'
  get '/info/:gem_name' => 'api/compact_index#info', as: :info
  get '/names' => 'api/compact_index#names'
  ################################################################################
  # API v0

  scope to: 'api/deprecated#index' do
    get 'api_key'
    put 'api_key/reset', to: 'api/deprecated#index'

    post 'gems'
    get 'gems/:id.json'

    scope path: 'gems/:rubygem_id' do
      put 'migrate'
      post 'migrate'
      get 'owners(.:format)'
      post 'owners(.:format)'
      delete 'owners(.:format)'
    end
  end

  ################################################################################
  # UI
  scope constraints: { format: :html }, defaults: { format: 'html' } do
    resource :search,    only: :show
    resource :dashboard, only: :show, constraints: { format: /html|atom/ }
    resources :profiles, only: :show
    resource :profile, only: [:edit, :update]
    resources :stats, only: :index
    resources :recent_uploads, only: :index

    resources :rubygems,
      only: [:index, :show, :edit, :update],
      path: 'gems',
      constraints: { id: Patterns::ROUTE_PATTERN, format: /html|atom/ } do
      resource :subscription,
        only: [:create, :destroy],
        constraints: { format: :js },
        defaults: { format: :js }
      resources :versions, only: [:show, :index]
    end
  end

  ################################################################################
  # Clearance Overrides

  resource :session, only: [:create, :destroy]

  resources :passwords, only: [:new, :create]

  resources :users, only: [:new, :create] do
    resource :password, only: [:create, :edit, :update]
  end

  ################################################################################
  # Internal Routes

  namespace :internal do
    get 'ping' => 'ping#index'
    get 'revision' => 'ping#revision'
  end

  use_doorkeeper scope: 'oauth'

  unless Clearance.configuration.allow_sign_up?
    get '/sign_up' => 'users#disabled_signup'
  end
end
