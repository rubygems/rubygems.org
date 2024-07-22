require_relative "../middleware"
require_relative "../../github_oauthable"
require_relative "../../trace_tagger"

class Gemcutter::Middleware::AdminAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    Context.new(env).call || @app.call(env)
  end

  class Context
    include GitHubOAuthable
    include TraceTagger

    def initialize(env)
      @request = ActionDispatch::Request.new(env)
      @cookies = request.cookie_jar
    end

    attr_reader :request, :cookies

    def call
      return unless requires_auth_for_admin?(request)
      admin_user = find_admin_user
      request.set_header(admin_user_request_header, admin_user)
      if admin_user.present?
        set_tag "gemcutter.admin_user.id", admin_user.id
        return
      end
      return if allow_unauthenticated_request?(request)
      login_page = ApplicationController.renderer.new(request.env).render(template: "avo/login", layout: false)

      headers = { "cache-control" => "private, max-age=0", "set-cookie" => cookies.to_header }
      headers.compact_blank!

      [200, headers, [login_page]]
    end

    private

    def requires_auth_for_admin?(request)
      # always required on the admin instance
      return true if request.host == Gemcutter::SEPARATE_ADMIN_HOST

      # always required for admin namespace
      return true if request.path.match?(%r{\A/admin(/|\z)})

      # running locally/staging, not trying to access admin namespace, safe to not require the admin auth
      false
    end

    def allow_unauthenticated_request?(request)
      request.path.match?(%r{\A/oauth(/|\z)})
    end
  end
end
