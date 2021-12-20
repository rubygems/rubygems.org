class AdoptionsController < ApplicationController
  before_action :find_rubygem
  before_action :verify_ownership_requestable

  def index
    @ownership_call     = @rubygem.ownership_call
    @user_request       = @rubygem.ownership_requests.find_by(user: current_user)
    @ownership_requests = @rubygem.ownership_requests.includes(:user)
  end

  private

  def verify_ownership_requestable
    render_forbidden unless @rubygem.ownership_requestable?
  end
end
