# frozen_string_literal: true

class OIDC::ProvidersController < ApplicationController
  include SessionVerifiable
  verify_session_before

  before_action :find_provider, except: %i[index]
  before_action :set_page, only: :index

  def index
    providers_pagy, providers = pagy(OIDC::Provider.strict_loading)
    render OIDC::Providers::IndexView.new(providers_pagy:, providers:)
  end

  def show
    render OIDC::Providers::ShowView.new(provider: @provider)
  end

  private

  def find_provider
    @provider = OIDC::Provider.find(params.permit(:id).require(:id))
  end
end
