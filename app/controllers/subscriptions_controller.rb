class SubscriptionsController < ApplicationController

  before_filter :find_gem

  def create
    subscription = @gem.subscriptions.build(:user => current_user)
    render_toggle_or_unacceptable(subscription.try(:save))
  end

  def destroy
    subscription = @gem.subscriptions.find_by_user_id(current_user.try(:id))
    render_toggle_or_unacceptable(subscription.try(:destroy))
  end

  protected

    def find_gem
      @gem = Rubygem.find_by_name(params[:rubygem_id])
    end

    def render_toggle_or_unacceptable(success)
      if success
        render :update
      else
        render :text => '', :status => :forbidden
      end
    end

end
