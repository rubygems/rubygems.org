class OIDC::ApiKeyRolesController < ApplicationController
  include ApiKeyable
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?
  before_action :redirect_to_verify, unless: :password_session_active?

  def index
    @api_key_roles = current_user.oidc_api_key_roles.strict_loading.includes(:provider)
  end

  def show
    @api_key_role = current_user.oidc_api_key_roles
      .includes(id_tokens: { api_key: nil }, provider: nil).strict_loading
      .find_by!(token: params.require(:token))
  end

  private

  def redirect_to_verify
    session[:redirect_uri] = request.path_info
    redirect_to verify_session_path
  end
end
