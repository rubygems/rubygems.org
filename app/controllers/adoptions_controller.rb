class AdoptionsController < ApplicationController
  before_action :find_rubygem
  before_action :verify_ownership_requestable
  before_action :redirect_to_verify, if: :current_user_is_owner?

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

  def redirect_to_verify
    return if password_session_active?
    session[:redirect_uri] = rubygem_adoptions_path(@rubygem)
    redirect_to verify_session_path
  end
end
