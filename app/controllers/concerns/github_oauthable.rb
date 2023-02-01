module GitHubOAuthable
  extend ActiveSupport::Concern

  included do
    def validate_admin_credentials!(username:, token:)
      client = Octokit::Client.new(:access_token => token)
      return render_not_found unless client.organization_membership('rubygems').state == 'active'
      return render_not_found unless active_team_membership?(client:, username:)
    end

    def active_team_membership?(org: 'rubygems', team: 'rubygems-org', client: admin_github_client, username: admin_githb_username)
      client.get("orgs/rubygems/teams/rubygems-org/memberships/#{username}").state == 'active'
    end

    def admin_github_client
      @admin_github_client ||= Octokit::Client.new(:access_token => cookies.encrypted["rubygems_admin_oauth_github"]["token"])
    end

    def admin_github_username
      @admin_githb_username ||= cookies.encrypted["rubygems_admin_oauth_github"]["username"]
    end
  end
end