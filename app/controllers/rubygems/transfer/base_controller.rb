class Rubygems::Transfer::BaseController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :find_or_initialize_transfer
  before_action :set_breadcrumbs

  def find_or_initialize_transfer
    @rubygem = Rubygem.find_by(name: params[:rubygem_id])
    @rubygem_transfer = RubygemTransfer.find_or_initialize_by(created_by: Current.user, rubygem: @rubygem, status: :pending)
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.gems"), rubygems_path
    add_breadcrumb @rubygem.name, rubygem_path(@rubygem)
    add_breadcrumb "Transfer Gem"
  end
end
