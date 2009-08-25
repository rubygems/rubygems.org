class DashboardsController < ApplicationController

  before_filter :redirect_to_root, :unless => :signed_in?

  def mine
    @gems = current_user.rubygems
  end

  def subscribed
    @gems = current_user.subscribed_gems
  end

end
