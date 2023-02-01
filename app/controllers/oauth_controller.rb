class OAuthController < ApplicationController
  rescue_from Octokit::ClientError, Octokit::ServerError, with: :render_not_found

  def create
    user_info = request.env["omniauth.auth"]
    unless user_info&.valid?
      Rails.logger.info("Invalid omniauth.auth")
      return render_not_found
    end
    unless user_info.provider == "github"
      Rails.logger.info("Not from github")
      return render_not_found
    end

    username = user_info.extra.raw_info.login
    token = user_info.credentials.token

    client = Octokit::Client.new(access_token: token)
    unless client.organization_membership("rubygems").state == "active"
      Rails.logger.info("#{username} is not an active member of the rubygems organization")
      return render_not_found
    end
    unless client.get("orgs/rubygems/teams/rubygems-org/memberships/#{user_info.extra.raw_info.login}").state == "active"
      Rails.logger.info("#{username} is not an active member of the rubygems-org team")
      return render_not_found
    end

    cookies.encrypted["rubygems_admin_oauth_github"] = {
      value: { username:, token: },
      expires: 1.hour,
      same_site: :lax
    }

    redirect_to request.env["omniauth.origin"].presence || "/admin"
  end

  def failure
    render_forbidden params.require(:message)
  end
end
