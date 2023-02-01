require_relative "../middleware"

class Gemcutter::Middleware::AdminAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    return @app.call(env) unless requires_auth_for_admin?(request)

    cookie = request.cookie_jar.encrypted["rubygems_admin_oauth_github"]
    if cookie
      request.flash.now[:admin_login] = "Logged in as a admin via GitHub as #{cookie['username']}"
      return @app.call(env)
    end

    return @app.call(env) if allow_unauthenticated_request?(request)

    [200, { "Cache-Control" => "private, max-age=0" }, [ApplicationController.renderer.new(env).render(inline: <<~ERB, locals: { request: })]]
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
