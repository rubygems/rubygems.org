class NotifiersController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?

  def show
    @ownerships = current_user.ownerships.by_indexed_gem_name
  end

  def update
    to_enable_push = []
    to_disable_push = []
    to_enable_owner = []
    to_disable_owner = []
    params.require(:ownerships).each do |ownership_id, notifier|
      (notifier["owner"] == "off" ? to_disable_owner : to_enable_owner) << ownership_id.to_i
      (notifier["push"] == "off" ? to_disable_push : to_enable_push) << ownership_id.to_i
    end

    current_user.transaction do
      current_user.ownerships.where(id: to_enable_push).update_all(push_notifier: true) if to_enable_push.any?
      current_user.ownerships.where(id: to_disable_push).update_all(push_notifier: false) if to_disable_push.any?
      current_user.ownerships.where(id: to_enable_owner).update_all(owner_notifier: true) if to_enable_owner.any?
      current_user.ownerships.where(id: to_disable_owner).update_all(owner_notifier: false) if to_disable_owner.any?
      Mailer.delay.notifiers_changed(current_user.id)
    end

    redirect_to notifier_path, notice: t(".update.success")
  end
end
