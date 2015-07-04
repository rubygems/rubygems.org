class SubscriptionsController < ApplicationController
  before_action :find_rubygem

  def create
    subscription = @rubygem.subscriptions.build(user: current_user)
    render_toggle_or_unacceptable(subscription.try(:save))
  end

  def destroy
    subscription = @rubygem.subscriptions.find_by_user_id(current_user.try(:id))
    render_toggle_or_unacceptable(subscription.try(:destroy))
  end

protected

  def render_toggle_or_unacceptable(success)
    if success
      respond_to do |format|
        format.js { render :update }
      end
    else
      render text: '', status: :forbidden
    end
  end

end
