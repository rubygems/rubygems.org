class OAuthController < ApplicationController
  include GitHubOAuthable

  rescue_from Octokit::ClientError, Octokit::ServerError, with: :render_not_found
  rescue_from ActiveModel::ValidationError do |e|
    render_forbidden e.message
  end

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

    admin_github_login!(token: user_info.credentials.token)

    redirect_to request.env["omniauth.origin"].presence || avo_root
  end

  def failure
    render_forbidden params.require(:message)
  end
end
