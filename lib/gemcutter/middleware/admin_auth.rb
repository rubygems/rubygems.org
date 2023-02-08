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
         <html>
         <head>
           <style>
             body {
               font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji";
               font-weight: bold;
               color: white;
             }

             a {
               color: white;
               text-decoration: none;
             }

             form {
               margin: auto;
               margin-top: 30vh;
               width: 220px;
               padding: 15px 20px;
               background-color: black;
               border-radius: 6px;
               display: flex;
               align-items: center;
               gap: 20px;
             }
           </style>
         </head>

         <body>
           <%= form_tag ActionDispatch::Http::URL.path_for(path: '/oauth/github', params: { origin: request.fullpath }) do %>
             <svg viewBox="0 0 16 16" height="48" width="48" focusable="false" role="img" fill="currentColor"
               xmlns="http://www.w3.org/2000/svg">
               <path
                 d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.012 8.012 0 0 0 16 8c0-4.42-3.58-8-8-8z">
               </path>
             </svg>
             <a onclick="this.parentNode.submit()" href="#">Login with GitHub</a>
           <% end %>
         </body>
         </html>
       ERB
    end

    private

    def requires_auth_for_admin?(request)
      # always required on the admin instance
      return true if Gemcutter::SEPARATE_ADMIN_HOST&.==(request.host)

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
