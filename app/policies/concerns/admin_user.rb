module AdminUser
  extend ActiveSupport::Concern

  included do
    def admin?
      user.is_a?(Admin::GitHubUser) && user.is_admin
    end

    def belongs_to_team?(slug)
      admin? && user.team_member?(slug)
    end

    def rubygems_org_admin?
      belongs_to_team?("rubygems-org")
    end
  end
end
