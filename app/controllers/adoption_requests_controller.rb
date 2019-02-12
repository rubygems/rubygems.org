class AdoptionRequestsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?
  before_action :find_rubygem
  before_action :find_adoption_request_and_requester, only: :update

  def create
    adoption_request = @rubygem.adoption_requests.build(adoption_request_params)

    if adoption_request.save
      Mailer.delay.adoption_requested(adoption_request)
      redirect_to rubygem_adoption_path(@rubygem), flash: { success: t(".success", gem: @rubygem.name) }
    else
      redirect_to rubygem_adoption_path(@rubygem), flash: { error: adoption_request.errors.full_messages.to_sentence }
    end
  end

  def update
    if params_status == "approved" && @rubygem.owned_by?(current_user)
      @rubygem.approve_adoption_request!(@adoption_request, current_user.id)
      Mailer.delay.adoption_request_approved(@rubygem, @requester)

      redirect_to_adoption_path
    elsif params_status == "closed" && current_user.can_close?(@adoption_request)
      @adoption_request.closed!
      Mailer.delay.adoption_request_closed(@rubygem, @requester) unless @requester == current_user

      redirect_to_adoption_path
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

  def find_adoption_request_and_requester
    @adoption_request = AdoptionRequest.find(params[:id])
    @requester = @adoption_request.user
  end

  def redirect_to_adoption_path
    message = t(".success", user: @requester.name, gem: @rubygem.name, status: @adoption_request.status)
    redirect_to rubygem_adoption_path(@rubygem), flash: { success: message }
  end
end
