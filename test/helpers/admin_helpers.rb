module AdminHelpers
  extend ActiveSupport::Concern

  included do
    def admin_sign_in_as(admin_user)
      cookie_jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
      cookie_jar.encrypted["rubygems_admin_oauth_github_user"] = admin_user.id
      cookies["rubygems_admin_oauth_github_user"] = cookie_jar["rubygems_admin_oauth_github_user"]
    end
  end
end
