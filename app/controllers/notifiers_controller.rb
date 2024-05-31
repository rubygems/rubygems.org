class NotifiersController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  def show
    @ownerships = current_user.ownerships.by_indexed_gem_name.includes(:rubygem)
  end

  def update
    to_enable_push, to_disable_push = notifier_options("push")
    to_enable_owner, to_disable_owner = notifier_options("owner")
    to_enable_ownership_request, to_disable_ownership_request = notifier_options("ownership_request")

    current_user.transaction do
      current_user.ownerships.update_push_notifier(to_enable_push, to_disable_push)
      current_user.ownerships.update_owner_notifier(to_enable_owner, to_disable_owner)
      current_user.ownerships.update_ownership_request_notifier(to_enable_ownership_request, to_disable_ownership_request)
      Mailer.notifiers_changed(current_user.id).deliver_later
    end

    redirect_to notifier_path, notice: t(".update.success")
  end

  private

  def notifier_params
    params.permit(ownerships: %i[push owner ownership_request]).require(:ownerships)
  end

  def notifier_options(param)
    to_enable  = []
    to_disable = []
    notifier_params.each do |ownership_id, notifier|
      (notifier[param] == "off" ? to_disable : to_enable) << ownership_id.to_i
    end

    [to_enable, to_disable]
  end
end
