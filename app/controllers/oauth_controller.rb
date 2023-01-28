require "net/http"

class OauthController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    case params[:provider]
    when "github"
      github_auth
    else
      render inline: "provider is #{params[:provider]}"
    end
  end

  def failure
    render inline: \
    <<~HTML
      <div>You reached this due to an error in OmniAuth</div>
      <div>Strategy: #{params['strategy']}</div>
      <div>Message: #{params['message']}</div>
    HTML
  end

  private

  def github_auth
    @auth = request.env["omniauth.auth"]
    @token = @auth["credentials"]["token"]
    @user = @auth["extra"]["raw_info"]

    if is_org_member? && is_team_member?
      @user = User.find_or_create_by(github_login: @user["login"])
      @user.update(email_confirmed: true) unless @user.email_confirmed?

      sign_in(@user) do |status|
        if status.success?
          redirect_back_or('/')
        else
          flash.now.notice = status.failure_message
          render template: "sessions/new", status: :unauthorized
        end
      end
    else
      raise
    end
  end

  def is_org_member?
    org_memberships = make_json_request(@user["organizations_url"])
    org_memberships.map { |org| org["login"] }.include?("rubygems")
  end

  def is_team_member?
    user_membership = make_json_request(membership_url)
    user_membership["state"] == "active"
  end

  def make_json_request(url)
    res = Net::HTTP.get_response(URI(url), "Authorization" => "Bearer #{@token}")
    JSON.parse(res.body)
  end

  def membership_url
    "https://api.github.com/orgs/rubygems/teams/rubygems-org/memberships/#{@user['login']}"
  end
end
