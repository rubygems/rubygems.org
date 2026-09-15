# frozen_string_literal: true

class OIDC::IdTokensController < ApplicationController
  include ApiKeyable

  include SessionVerifiable

  verify_session_before

  before_action :find_id_token, except: %i[index]
  before_action :set_page, only: :index

  layout "subject"

  def index
    add_breadcrumb(t("breadcrumbs.settings"), edit_settings_path)
    add_breadcrumb(t(".title"))

    id_tokens = current_user.oidc_id_tokens.includes(:api_key, :api_key_role, :provider)
      .page(@page)
      .strict_loading
    render OIDC::IdTokens::IndexView.new(id_tokens:)
  end

  def show
    add_breadcrumb(t("breadcrumbs.settings"), edit_settings_path)
    add_breadcrumb(t("oidc.id_tokens.index.title"), profile_oidc_id_tokens_path)
    add_breadcrumb(@id_token.jti)

    render OIDC::IdTokens::ShowView.new(id_token: @id_token)
  end

  private

  def find_id_token
    @id_token = current_user.oidc_id_tokens.find(params.expect(:id))
  end
end
