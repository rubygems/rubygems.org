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
          number: /#{Gem::Version::VERSION_PATTERN}(?=\.(json|yaml|sha256)\z)|#{Gem::Version::VERSION_PATTERN}/o
        } do
          resources :contents, only: :index, constraints: {
            version_number: /#{Gem::Version::VERSION_PATTERN}/o,
            format: /json|yaml|sha256/
          }
        end
      end
    end

    namespace :v1 do
      resource :api_key, only: %i[show create update] do
        collection do
          post :revoke, to: "github_secret_scanning#revoke", defaults: { format: :json }
        end
      end
      resource :multifactor_auth, only: :show
      resource :webauthn_verification, only: :create do
        get ':webauthn_token/status', action: :status, as: :status, constraints: { format: :json }
      end
      resources :profiles, only: :show
      get "profile/me", to: "profiles#me"
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
          delete :yank, to: "deletions#create"
        end
        constraints rubygem_id: Patterns::ROUTE_PATTERN do
          resource :owners, only: %i[show create destroy]
          resources :trusted_publishers, controller: 'oidc/rubygem_trusted_publishers', only: %i[index create destroy show]
        end
      end

      resource :activity, only: [], format: /json|yaml/ do
        collection do
          get :latest
          get :just_updated
        end
      end

      resource :search, only: :show do
        get :autocomplete
      end

      resources :web_hooks, only: %i[create index] do
        collection do
          delete :remove
          post :fire
          post :hook_relay_report, to: 'hook_relay#report', defaults: { format: :json }
        end
      end

      resources :timeframe_versions, only: :index

      namespace :oidc do
        post 'trusted_publisher/exchange_token'
        resources :api_key_roles, only: %i[index show], param: :token, format: 'json', defaults: { format: :json } do
          member do
            post :assume_role
          end
        end

        resources :providers, only: %i[index show], format: 'json', defaults: { format: :json }

        resources :id_tokens, only: %i[index show], format: 'json', defaults: { format: :json }
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
    put 'api/v1/gems/unyank'
    put 'api/v1/api_key/reset'

    post 'gems'
    get 'gems/:id.json'

    scope path: 'gems/:rubygem_id' do
      put 'migrate'
      post 'migrate'
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
    get "profile/me", to: "profiles#me", as: :my_profile
    resource :multifactor_auth, only: %i[update] do
      get 'recovery'
      post 'otp_update', to: 'multifactor_auths#otp_update', as: :otp_update
      post 'webauthn_update', to: 'multifactor_auths#webauthn_update', as: :webauthn_update
    end
    resource :totp, only: %i[new create destroy]
    resource :settings, only: :edit
    resource :profile, only: %i[edit update] do
      get :adoptions
      get :security_events
      member do
        get :delete
        delete :destroy, as: :destroy
      end

      resources :api_keys do
        delete :reset, on: :collection
      end

      namespace :oidc do
        resources :api_key_roles, param: :token do
          member do
            get 'github_actions_workflow'
          end
        end
        resources :api_key_roles, param: :token, only: %i[show], constraints: { format: :json }
        resources :id_tokens, only: %i[index show]
        resources :providers, only: %i[index show]
        resources :pending_trusted_publishers, except: %i[show edit update]
      end
    end
    resources :stats, only: :index
    get "/news" => 'news#show', as: 'legacy_news_path'
    resource :news, path: 'releases', only: [:show] do
      get :popular, on: :collection
    end
    resource :notifier, only: %i[update show]

    resources :rubygems,
      only: %i[index show],
      path: 'gems',
      constraints: { id: Patterns::ROUTE_PATTERN, format: /html|atom/ } do
      get :security_events, on: :member

      resource :subscription,
        only: %i[create destroy],
        constraints: { format: :js },
        defaults: { format: :js }
      resources :versions, only: %i[show index] do
        get '/dependencies', to: 'dependencies#show', constraints: { format: /json|html/ }
      end
      resources :reverse_dependencies, only: %i[index]
      resources :owners, only: %i[index destroy create], param: :handle do
        get 'confirm', to: 'owners#confirm', as: :confirm, on: :collection
        get 'resend_confirmation', to: 'owners#resend_confirmation', as: :resend_confirmation, on: :collection
      end
      resource :ownership_calls, only: %i[update create] do
        patch 'close', to: 'ownership_calls#close', as: :close, on: :collection
      end
      resources :ownership_requests, only: %i[create update] do
        patch 'close_all', to: 'ownership_requests#close_all', as: :close_all, on: :collection
      end
      resources :adoptions, only: %i[index]
      resources :trusted_publishers, controller: 'oidc/rubygem_trusted_publishers', only: %i[index create destroy new]
    end

    resources :ownership_calls, only: :index
    resources :webauthn_credentials, only: :destroy
    resource :webauthn_verification, only: [] do
      get 'successful_verification'
      get 'failed_verification'
      get ':webauthn_token', to: 'webauthn_verifications#prompt', as: ''
    end

    ################################################################################
    # Clearance Overrides and Additions

    resource :email_confirmations, only: %i[new create] do
      get 'confirm', to: 'email_confirmations#update', as: :update
      post 'otp_update', to: 'email_confirmations#otp_update', as: :otp_update
      post 'webauthn_update', to: 'email_confirmations#webauthn_update', as: :webauthn_update
      patch 'unconfirmed'
    end

    resource :password, only: %i[new create edit update] do
      post 'otp_edit', to: 'passwords#otp_edit', as: :otp_edit
      post 'webauthn_edit', to: 'passwords#webauthn_edit', as: :webauthn_edit
    end

    resource :session, only: %i[create destroy] do
      post 'otp_create', to: 'sessions#otp_create', as: :otp_create
      post 'webauthn_create', to: 'sessions#webauthn_create', as: :webauthn_create
      post 'webauthn_full_create', to: 'sessions#webauthn_full_create', as: :webauthn_full_create
      get 'verify', to: 'sessions#verify', as: :verify
      post 'authenticate', to: 'sessions#authenticate', as: :authenticate
      post 'webauthn_authenticate', to: 'sessions#webauthn_authenticate', as: :webauthn_authenticate
    end

    resources :users, only: %i[new create]

    get '/sign_in' => 'sessions#new', as: 'sign_in'
    delete '/sign_out' => 'sessions#destroy', as: 'sign_out'

    get '/sign_up' => 'users#new', as: 'sign_up' if Clearance.configuration.allow_sign_up?
  end

  ################################################################################
  # UI API

  scope constraints: { format: :json }, defaults: { format: :json } do
    resources :webauthn_credentials, only: :create do
      post :callback, on: :collection
    end
  end

  scope constraints: { format: :text }, defaults: { format: :text } do
    resource :webauthn_verification, only: [] do
      post ':webauthn_token', to: 'webauthn_verifications#authenticate', as: :authenticate
    end
  end

  ################################################################################
  # UI Images

  scope constraints: { format: /jpe?g/ }, defaults: { format: :jpeg } do
    resources :users, only: [] do
      get 'avatar', on: :member, to: 'avatars#show', format: true
    end
  end

  ################################################################################
  # static pages routes
  get 'pages/*id' => 'pages#show', constraints: { format: :html, id: Regexp.union(Gemcutter::PAGES) }, as: :page

  ################################################################################
  # Internal Routes

  namespace :internal do
    get 'ping' => 'ping#index'
    get 'revision' => 'ping#revision'
  end

  ################################################################################
  # Incoming Webhook Endpoint

  if Rails.env.local? || (ENV['SENDGRID_WEBHOOK_USERNAME'].present? && ENV['SENDGRID_WEBHOOK_PASSWORD'].present?)
    resources :sendgrid_events, only: :create, format: false, defaults: { format: :json }
  end

  ################################################################################
  # Admin routes

  constraints({ host: Gemcutter::SEPARATE_ADMIN_HOST }.compact) do
    namespace :admin, constraints: { format: :html }, defaults: { format: 'html' } do
      delete 'logout' => 'admin#logout', as: :logout
    end

    constraints(Constraints::Admin) do
      namespace :admin, constraints: Constraints::Admin::RubygemsOrgAdmin do
        mount GoodJob::Engine, at: 'good_job'
        mount MaintenanceTasks::Engine, at: "maintenance_tasks"
        mount PgHero::Engine, at: "pghero"
      end

      mount Avo::Engine, at: Avo.configuration.root_path
    end
  end

  scope :oauth, constraints: { format: :html }, defaults: { format: 'html' } do
    get ':provider/callback', to: 'oauth#create'
    get 'failure', to: 'oauth#failure'

    get 'development_log_in_as/:admin_github_user_id', to: 'oauth#development_log_in_as' if Gemcutter::ENABLE_DEVELOPMENT_ADMIN_LOG_IN
  end

  ################################################################################
  # Development routes

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Lookbook::Engine, at: "/lookbook"
  end
end
