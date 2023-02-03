require_relative "../middleware"

module GitHubOAuthable
  extend ActiveSupport::Concern

  INFO_QUERY = <<~GRAPHQL.freeze
    query($organization_name:String!) {
      viewer {
        name
        login
        email
        avatarUrl
        id
        organization(login: $organization_name) {
          login
          name
          viewerIsAMember
          teams(first: 20, role: MEMBER) {
            edges {
              node {
                name
                slug
              }
            }
          }
        }
      }
    }
  GRAPHQL

  included do
    def admin_user
      return unless (cookie = cookies.encrypted[admin_cookie_name].presence)
      Admin::GitHubUser.admins.find(cookie)
    end

    def admin_logout
      cookies.delete(admin_cookie_name)
      redirect_to root_path
    end

    def admin_github_login!(token:)
      info_data = fetch_admin_user_info(token)
      user = Admin::GitHubUser.find_or_initialize_by(github_id: info_data.dig(:viewer, :id))
      user.is_admin = true # will be set to false if the is_admin validation fails
      user.oauth_token = token
      user.info_data = info_data
      if user.invalid? && user.errors.group_by_attribute.keys == %i[is_admin]
        is_admin_error = ActiveModel::ValidationError.new(user)
        user.is_admin = false
      end
      user.save!

      if user.is_admin
        request.flash.now[:warning] = "Logged in as a admin via GitHub as #{user.name}"
        cookies.encrypted[admin_cookie_name] = {
          value: user.id,
          expires: 1.hour,
          same_site: :lax
        }
      else
        request.flash[:error] = "#{user.name} on GitHub is not a valid admin"
        raise is_admin_error
      end
    end

    def admin_cookie_name
      "rubygems_admin_oauth_github_user"
    end

    def fetch_admin_user_info(oauth_token)
      github_client = Octokit::Client.new(access_token: oauth_token)
      graphql = github_client.post(
        "/graphql",
        { query: INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json
      )
      if (errors = graphql.errors.presence)
        Rails.logger.warn("GitHub graphql errors: #{errors}")
      end
      graphql.data.to_h.deep_symbolize_keys
    end
  end
end

class Gemcutter::Middleware::AdminAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    Context.new(env).call || @app.call(env)
  end

  class Context
    include GitHubOAuthable

    def initialize(env)
      @request = ActionDispatch::Request.new(env)
      @cookies = request.cookie_jar
    end

    attr_reader :request, :cookies

    def call
      return unless requires_auth_for_admin?(request)
      return if admin_user.present?
      return if allow_unauthenticated_request?(request)

      [200, { "Cache-Control" => "private, max-age=0" },
       [ApplicationController.renderer.new(request.env).render(inline: <<~ERB, locals: { request: })]]
         <div class="t-body">
           <%= button_to("Login with GitHub",
                         ActionDispatch::Http::URL.path_for(path: '/oauth/github', params: { origin: request.fullpath }),
                         method: 'post',
                         authenticity_token: true,
                         form: {
                           data: {turbo: false},
                         })
                         %>
         </div>
       ERB
    end

    private

    def requires_auth_for_admin?(request)
      # always required on the admin instance
      return true if Rails.env.production? && ENV["RUBYGEMS_ENABLE_ADMIN"]

      # always required for admin namespace
      return true if request.path.match?(%r{\A/admin(/|\z)})

      # running locally/staging, not trying to access admin namespace, safe to not require the admin auth
      false
    end

    def allow_unauthenticated_request?(request)
      request.path.match?(%r{\A/auth(/|\z)})
    end
  end
end
