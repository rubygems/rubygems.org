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
        only: %i[create show index],
        id: Patterns::LAZY_ROUTE_PATTERN,
        format: /json|yaml/ do
        member do
          get :reverse_dependencies
        end
        collection do
          get :audit, to: "audits#check"
          delete :yank, to: "deletions#create"
          put :unyank, to: "deletions#destroy"
          post :advisory, to: "advisories#create"
        end
        constraints rubygem_id: Patterns::ROUTE_PATTERN do
          resource :owners, only: %i[show create destroy]
        end
      end

      resource :activity, only: [], format: /json|yaml/ do
        collection do
          get :latest
          get :just_updated
        end
      end

      resource :search, only: :show

      resources :web_hooks, only: %i[create index] do
        collection do
          delete :remove
          post :fire
        end
      end
    end
  end

  get '/versions' => 'api/compact_index#versions'
  get '/info/:gem_name' => 'api/compact_index#info', as: :info,
      constraints: { gem_name: Patterns::ROUTE_PATTERN }
  get '/names' => 'api/compact_index#names'
  ################################################################################
  # API v0

  scope controller: 'api/deprecated', action: 'index' do
    get 'api_key'
    put 'api_key/reset'

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
    resource :search, only: :show do
      get :advanced
    end
    resource :dashboard, only: :show, constraints: { format: /html|atom/ }
    resources :profiles, only: :show
    resource :multifactor_auth, only: %i[new create destroy]
    resource :profile, only: %i[edit update] do
      member do
        get :delete
        delete :destroy, as: :destroy
      end
    end
    resources :stats, only: :index
    resource :news, path: 'news', only: [:show] do
      get :popular, on: :collection
    end

    resources :rubygems,
      only: %i[index show edit update],
      path: 'gems',
      constraints: { id: Patterns::ROUTE_PATTERN, format: /html|atom/ } do
      resource :subscription,
        only: %i[create destroy],
        constraints: { format: :js },
        defaults: { format: :js }
      resources :versions, only: %i[show index]
      resources :reverse_dependencies, only: %i[index]
    end
  end

  ################################################################################
  # Clearance Overrides and Additions

  resource :email_confirmations, only: %i[new create] do
    get 'confirm/:token', to: 'email_confirmations#update', as: :update
    patch 'unconfirmed'
  end

  resource :session, only: %i[create destroy] do
    post 'mfa_create', to: 'sessions#mfa_create', as: :mfa_create
  end

  resources :passwords, only: %i[new create]

  resources :users, only: %i[new create] do
    resource :password, only: %i[create edit update]
  end

  ################################################################################
  # Internal Routes

  namespace :internal do
    get 'ping' => 'ping#index'
    get 'revision' => 'ping#revision'
  end

  get '/sign_up' => 'users#disabled_signup' unless Clearance.configuration.allow_sign_up?
end
