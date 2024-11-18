class SubscriptionsController < ApplicationController
  before_action :redirect_to_signin, only: :index, unless: :signed_in?
  before_action :redirect_to_new_mfa, only: :index, if: :mfa_required_not_yet_enabled?
  before_action :redirect_to_settings_strong_mfa_required, only: :index, if: :mfa_required_weak_level_enabled?

  before_action :find_rubygem, only: %i[create destroy]

  layout "subject"

  def index
    add_breadcrumb t("breadcrumbs.dashboard"), dashboard_path
    add_breadcrumb t("breadcrumbs.subscriptions")

    @subscribed_gems = current_user
      .subscribed_gems
      .with_versions
      .by_name
      .preload(:most_recent_version)
      .load_async
  end

  def create
    subscription = @rubygem.subscriptions.build(user: current_user)
    redirect_to_rubygem(subscription&.save)
  end

  def destroy
    subscription = @rubygem.subscriptions.find_by_user_id(current_user&.id)
    redirect_to_rubygem(subscription&.destroy)
  end

  protected

  def redirect_to_rubygem(success)
    flash[:error] = t("try_again") unless success
    redirect_to rubygem_path(@rubygem.slug)
  end
end
