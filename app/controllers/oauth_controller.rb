class OAuthController < ApplicationController
  include GitHubOAuthable

  rescue_from Octokit::ClientError, Octokit::ServerError, with: :render_not_found
  rescue_from ActiveModel::ValidationError do |e|
    render_forbidden e.message
  end

  with_options only: :create do
    before_action :check_valid_omniauth
    before_action :check_supported_omniauth_provider
  end

  def create
    admin_github_login!(token: request.env["omniauth.auth"].credentials.token)

    redirect_to request.env["omniauth.origin"].presence || avo_root_path
  end

  def failure
    render_forbidden params.require(:message)
  end

  private

  def check_valid_omniauth
    render_not_found unless request.env["omniauth.auth"]&.valid?
  end

  def check_supported_omniauth_provider
    render_not_found unless request.env["omniauth.auth"].provider == "github"
  end
end
