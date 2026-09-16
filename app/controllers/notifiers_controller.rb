# frozen_string_literal: true

class NotifiersController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?

  layout "subject"

  def show
    @ownerships = current_user.ownerships.by_indexed_gem_name.includes(:rubygem)
    @memberships = current_user.memberships.confirmed.by_organization_handle.includes(:organization)
    @title = t(".title")
    add_breadcrumb(t("breadcrumbs.settings"), edit_settings_path)
    add_breadcrumb(@title)
  end

  def update
    to_enable_ownership_push, to_disable_ownership_push = notifier_options(notifier_params, "push")
    to_enable_ownership_owner, to_disable_ownership_owner = notifier_options(notifier_params, "owner")
    to_enable_membership_push, to_disable_membership_push = notifier_options(membership_params, "push")

    current_user.transaction do
      current_user.ownerships.update_push_notifier(to_enable_ownership_push, to_disable_ownership_push)
      current_user.ownerships.update_owner_notifier(to_enable_ownership_owner, to_disable_ownership_owner)
      current_user.memberships.update_push_notifier(to_enable_membership_push, to_disable_membership_push)
      Mailer.notifiers_changed(current_user.id).deliver_later
    end

    redirect_to notifier_path, notice: t(".update.success")
  end

  private

  def notifier_params
    return {} unless params.key?(:ownerships)

    params.expect(ownerships: [%i[push owner]])
  end

  def membership_params
    return {} unless params.key?(:memberships)

    params.expect(memberships: [%i[push]])
  end

  def notifier_options(records, param)
    to_enable  = []
    to_disable = []
    records.each do |record_id, notifier|
      (notifier[param] == "off" ? to_disable : to_enable) << record_id.to_i
    end

    [to_enable, to_disable]
  end
end
