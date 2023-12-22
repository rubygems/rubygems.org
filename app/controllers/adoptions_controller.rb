class AdoptionsController < ApplicationController
  include SessionVerifiable

  before_action :find_rubygem
  before_action :verify_ownership_requestable
  before_action :redirect_to_verify, if: -> { current_user_is_owner? && !verified_session_active? }

  def index
    @ownership_call     = @rubygem.ownership_call
    @user_request       = @rubygem.ownership_requests.find_by(user: current_user)
    @ownership_requests = @rubygem.ownership_requests.includes(:user)
  end

  private

  def verify_ownership_requestable
    render_forbidden unless @rubygem.owned_by?(current_user) || @rubygem.ownership_requestable?
  end

  def current_user_is_owner?
    @rubygem.owned_by?(current_user)
  end
end
