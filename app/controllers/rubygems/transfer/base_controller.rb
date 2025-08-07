class Rubygems::Transfer::BaseController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :find_or_initialize_transfer
  before_action :set_breadcrumbs

  rescue_from Pundit::NotAuthorizedError, Pundit::NotDefinedError, with: :render_not_found

  def find_or_initialize_transfer
    @rubygem_transfer = RubygemTransfer
      .includes(invites: :user)
      .where.not(status: :completed)
      .find_or_initialize_by(created_by: Current.user)
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.gems"), rubygems_path
    add_breadcrumb "Transfer"
  end
end
