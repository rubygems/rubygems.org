class NotifiersController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?

  def show
    @ownerships = current_user.ownerships.by_indexed_gem_name
  end

  def update
    to_enable = []
    to_disable = []
    params.require(:ownerships).each do |ownership_id, notifier|
      (notifier == "off" ? to_disable : to_enable) << ownership_id.to_i
    end

    current_user.transaction do
      current_user.ownerships.where(id: to_enable).update_all(notifier: true) if to_enable.any?
      current_user.ownerships.where(id: to_disable).update_all(notifier: false) if to_disable.any?
      Mailer.delay.notifiers_changed(current_user.id)
    end

    redirect_to notifier_path, notice: t(".update.success")
  end
end
