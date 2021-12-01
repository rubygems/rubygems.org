class AdoptionsController < ApplicationController
  before_action :find_rubygem

  def index
    @ownership_call     = @rubygem.ownership_call
    @user_request       = @rubygem.ownership_requests.find_by(user: current_user)
    @ownership_requests = @rubygem.ownership_requests.includes(:user)
  end
end
