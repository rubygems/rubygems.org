class SubscriptionsController < ApplicationController
  before_filter :find_rubygem

  def create
    subscription = @rubygem.subscriptions.build(:user => current_user)
    render_toggle_or_unacceptable(subscription.try(:save))
  end

  def destroy
    subscription = @rubygem.subscriptions.find_by_user_id(current_user.try(:id))
    render_toggle_or_unacceptable(subscription.try(:destroy))
  end

protected

    # def render_toggle_or_unacceptable(success)
    #   if success
    #     render :update
    #   else
    #     render :text => '', :status => :forbidden
    #   end
  def render_toggle_or_unacceptable(success)
    if success
      render(:update) { |page| page['.toggler'].toggle }
    else
      render :text => '', :status => :forbidden
    end
  end

end
