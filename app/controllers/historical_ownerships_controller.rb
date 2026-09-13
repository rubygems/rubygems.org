# frozen_string_literal: true

class HistoricalOwnershipsController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  before_action :find_historical_ownership, only: :update

  layout "subject", only: :index

  def index
    @historical_ownerships = current_user.historical_ownerships.includes(:rubygem).order(first_owned_at: :desc)
  end

  def update
    if ActiveModel::Type::Boolean.new.cast(params[:private])
      @historical_ownership.make_private!
    else
      @historical_ownership.make_public!
    end

    redirect_to profile_historical_ownerships_path, notice: t(".success_notice")
  end

  private

  def find_historical_ownership
    @historical_ownership = current_user.historical_ownerships.find(params.expect(:id))
  end
end
