class Rubygems::TransfersController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :find_rubygem

  def destroy
    @rubygem_transfer = RubygemTransfer.find_by(created_by: Current.user, status: :pending)
    @rubygem_transfer&.destroy!

    redirect_to dashboard_path, notice: t("rubygems.transfer.cancelled")
  end

  private

  def find_rubygem
    @rubygem = Rubygem.find_by(name: params[:rubygem_id])
  end
end
