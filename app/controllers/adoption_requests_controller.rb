class AdoptionRequestsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?
  before_action :find_rubygem
  before_action :find_adoption_request, only: :update
  before_action :find_requester, only: :update

  def create
    @adoption_request = @rubygem.adoption_requests.create(adoption_request_params)

    if @adoption_request
      Mailer.delay.adoption_requested(@adoption_request)
      redirect_to rubygem_adoptions_path(@rubygem), flash: { success: t(".success", gem: @rubygem.name) }
    else
      render_bad_request
    end
  end

  def update
    if params_status == "approved" && @rubygem.owned_by?(current_user)
      @rubygem.approve_adoption_request!(@adoption_request, current_user.id)
      Mailer.delay.adoption_request_approved(@rubygem, @requester)

      redirect_to_adoptions_path
    elsif params_status == "canceled" && current_user.can_cancel?(@adoption_request)
      @adoption_request.canceled!
      Mailer.delay.adoption_request_canceled(@rubygem, @requester) unless @requester == current_user

      redirect_to_adoptions_path
    else
      render_bad_request
    end
  end

  private

  def adoption_request_params
    params.require(:adoption_request).permit(:note).merge(user_id: current_user.id, status: :opened)
  end

  def params_status
    params[:adoption_request][:status]
  end

  def find_adoption_request
    @adoption_request = AdoptionRequest.find(params[:id])
  end

  def find_requester
    @requester = User.find(@adoption_request.user_id)
  end

  def redirect_to_adoptions_path
    message = t(".success", user: @requester.name, gem: @rubygem.name, status: @adoption_request.status)
    redirect_to rubygem_adoptions_path(@rubygem), flash: { success: message }
  end

  def render_bad_request
    render plain: "Invalid adoption request", status: :bad_request
  end
end
