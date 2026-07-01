# frozen_string_literal: true

class OIDC::ProvidersController < ApplicationController
  include SessionVerifiable

  verify_session_before

  before_action :find_provider, except: %i[index]
  before_action :set_page, only: :index

  layout "subject"

  def index
    add_breadcrumb(t("breadcrumbs.settings"), edit_settings_path)
    add_breadcrumb(t(".title"))

    providers = OIDC::Provider.strict_loading.page(@page)
    render OIDC::Providers::IndexView.new(providers:)
  end

  def show
    add_breadcrumb(t("breadcrumbs.settings"), edit_settings_path)
    add_breadcrumb(t("oidc.providers.index.title"), profile_oidc_providers_path)
    add_breadcrumb(@provider.issuer)

    render OIDC::Providers::ShowView.new(provider: @provider)
  end

  private

  def find_provider
    @provider = OIDC::Provider.find(params.expect(:id))
  end
end
