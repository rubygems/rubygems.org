class Organizations::Onboarding::ConfirmController < Organizations::Onboarding::BaseController
  layout "onboarding"

  def edit
  end

  def update
    if @organization_onboarding.onboard!
      flash[:notice] = "Organization onboarded successfully!"
      redirect_to organization_path(@organization_onboarding.organization)
    else
      flash.now[:error] = "Onboarding error: #{@organization_onboarding.error}"
      render :edit, status: :unprocessable_entity
    end
  end
end
