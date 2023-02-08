require_relative "../middleware"
require_relative "../../github_oauthable"

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
      return true if Gemcutter::SEPARATE_ADMIN_HOST&.(request.host)

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
