require_relative "../middleware"

module GitHubOAuthable
  extend ActiveSupport::Concern

  included do
    def admin_user
      request.fetch_header("github_oauthable.admin_user") do
        return unless (cookie = cookies.encrypted["rubygems_admin_oauth_github"].presence)
        user = User.new(**cookie.symbolize_keys.slice(:token, :data))
        user if user.valid?
      end
    end

    def admin_logout
      cookies.delete(admin_cookie_name)
      redirect_to root_path
    end

    def admin_github_login!(token:)
      user = User.new(token:, data: nil)
      user.fetch_user_info
      unless user.valid?
        Rails.logger.warn("Invalid admin user trying to log in: #{user}")
        raise Octokit::ClientError
      end
      request.set_header("github_oauthable.admin_user", user)
      request.flash.now[:warning] = "Logged in as a admin via GitHub as #{user.name}"
      cookies.encrypted[admin_cookie_name] = {
        value: user,
        expires: 1.hour,
        same_site: :lax
      }
    end

    def admin_cookie_name
      "rubygems_admin_oauth_github"
    end
  end

  class User
    def initialize(token:, data:)
      @token = token
      @data = data&.deep_symbolize_keys
    end

    attr_reader :token, :data

    def to_hash
      { token:, data: }
    end

    def name
      data.dig(:viewer, :login)
    end

    def avatar
      data.dig(:viewer, :avatarUrl)
    end

    def team?(slug)
      data.dig(:viewer, :organization, :teams, :edges).any? { |edge| edge.dig(:node, :slug) == slug }
    end

    def valid?
      return if token.blank?
      return if data.blank?
      return if data.dig(:viewer, :login).blank?
      return unless data.dig(:viewer, :organization, :name) == "RubyGems"
      return unless data.dig(:viewer, :organization, :viewerIsAMember) == true
      return unless team?("rubygems-org")

      true
    end

    def github_client
      @github_client ||= Octokit::Client.new(access_token: token)
    end

    INFO_QUERY = <<~GRAPHQL.freeze
      {
        viewer {
          name
          login
          email
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
          avatarUrl
        }
      }
    GRAPHQL

    def fetch_user_info
      graphql = github_client.post(
        "/graphql",
        { query: INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json
      )
      if (errors = graphql.errors.presence)
        Rails.logger.warn("GitHub graphql errors: #{errors}")
      end
      @data = graphql.data.to_h.deep_symbolize_keys
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
