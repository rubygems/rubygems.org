class SubscriptionsController < ApplicationController
  before_action :find_rubygem

  def create
    subscription = @rubygem.subscriptions.build(user: current_user)
    redirect_to_rubygem(subscription.try(:save))
  end

  def destroy
    subscription = @rubygem.subscriptions.find_by_user_id(current_user.try(:id))
    redirect_to_rubygem(subscription.try(:destroy))
  end

  protected

  def redirect_to_rubygem(success)
    flash[:notice] = t('try_again') unless success
    redirect_to rubygem_path(@rubygem)
  end
end
