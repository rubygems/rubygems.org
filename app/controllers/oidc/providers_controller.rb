# frozen_string_literal: true

class OIDC::ProvidersController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?
  before_action :redirect_to_verify, unless: :password_session_active?
  before_action :find_provider, except: %i[index]
  before_action :set_page, only: :index

  def index
    providers = OIDC::Provider.all.strict_loading.page(@page)
    render OIDC::Providers::IndexView.new(providers:)
  end

  def show
    render OIDC::Providers::ShowView.new(provider: @provider)
  end

  private

  def find_provider
    @provider = OIDC::Provider.find(params.require(:id))
  end

  def redirect_to_verify
    session[:redirect_uri] = request.path_info
    redirect_to verify_session_path
  end
end
