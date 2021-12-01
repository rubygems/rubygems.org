class NotifiersController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?

  def show
    @ownerships = current_user.ownerships.by_indexed_gem_name
  end

  def update
    to_enable_push, to_disable_push = notifier_options("push")
    to_enable_owner, to_disable_owner = notifier_options("owner")
    to_enable_ownership_request, to_disable_ownership_request = notifier_options("ownership_request")

    current_user.transaction do
      current_user.ownerships.update_push_notifier(to_enable_push, to_disable_push)
      current_user.ownerships.update_owner_notifier(to_enable_owner, to_disable_owner)
      current_user.ownerships.update_ownership_request_notifier(to_enable_ownership_request, to_disable_ownership_request)
      Mailer.delay.notifiers_changed(current_user.id)
    end

    redirect_to notifier_path, notice: t(".update.success")
  end

  private

  def notifier_params
    params.require(:ownerships)
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
