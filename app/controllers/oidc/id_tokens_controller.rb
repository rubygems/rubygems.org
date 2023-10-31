# frozen_string_literal: true

class OIDC::IdTokensController < ApplicationController
  include ApiKeyable

  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?
  before_action :redirect_to_verify, unless: :password_session_active?
  before_action :find_id_token, except: %i[index]
  before_action :set_page, only: :index

  def index
    id_tokens = current_user.oidc_id_tokens.includes(:api_key, :api_key_role, :provider)
      .page(@page)
      .strict_loading
    render OIDC::IdTokens::IndexView.new(id_tokens:)
  end

  def show
    render OIDC::IdTokens::ShowView.new(id_token: @id_token)
  end

  private

  def find_id_token
    @id_token = current_user.oidc_id_tokens.find(params.require(:id))
  end

  def redirect_to_verify
    session[:redirect_uri] = request.path_info
    redirect_to verify_session_path
  end
end
