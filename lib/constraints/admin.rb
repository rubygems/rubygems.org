class Constraints::Admin
  def self.matches?(request)
    Matcher.new(request).admin_user&.valid?
  end

  class Matcher
    include GitHubOAuthable

    def initialize(request)
      @request = ActionDispatch::Request.new(request.env)
      @cookies = request.cookie_jar
    end
    attr_reader :request, :cookies

    def admin_user
      request.fetch_header(admin_user_request_header) { nil }
    end
  end

  class RubygemsOrgAdmin
    def self.matches?(request)
      admin_user = Matcher.new(request).admin_user
      return false unless admin_user&.valid?
      admin_user.team_member?("rubygems-org")
    end
  end
end
