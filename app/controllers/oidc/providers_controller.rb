# frozen_string_literal: true

class OIDC::ProvidersController < ApplicationController
  include SessionVerifiable
  verify_session_before

  before_action :find_provider, except: %i[index]
  before_action :set_page, only: :index

  def index
    providers = OIDC::Provider.strict_loading.page(@page)
    render OIDC::Providers::IndexView.new(providers:)
  end

  def show
    render OIDC::Providers::ShowView.new(provider: @provider)
  end

  private

  def find_provider
    @provider = OIDC::Provider.find(params_fetch(:id))
  end
end
