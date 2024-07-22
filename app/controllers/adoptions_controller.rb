class AdoptionsController < ApplicationController
  include SessionVerifiable

  before_action :find_rubygem
  before_action :redirect_to_verify, if: -> { @rubygem.owned_by?(current_user) && !verified_session_active? }

  def index
    @ownership_call     = @rubygem.ownership_call
    @user_request       = @rubygem.ownership_requests.find_by(user: current_user)
    @ownership_requests = @rubygem.ownership_requests.preload(:user)
  end

  private

  def find_rubygem
    super
    authorize @rubygem, :show_adoption? if @rubygem
  end
end
