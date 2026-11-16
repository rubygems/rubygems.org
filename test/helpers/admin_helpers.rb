# frozen_string_literal: true

module AdminHelpers
  extend ActiveSupport::Concern

  included do
    def admin_sign_in_as(admin_user)
      cookie_jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
      cookie_jar.encrypted["rubygems_admin_oauth_github_user"] = admin_user.id
      cookies["rubygems_admin_oauth_github_user"] = cookie_jar["rubygems_admin_oauth_github_user"]
    end

    def admin_outside_rubygems_org_team
      admin = create(:admin_github_user, :is_admin)
      info_data = admin.info_data.deep_dup
      info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
      admin.update!(info_data:)
      admin
    end
  end
end
