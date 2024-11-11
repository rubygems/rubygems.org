class Organizations::Onboarding::NameController < Organizations::Onboarding::BaseController
  layout "onboarding"

  def new
  end

  def create
    if @organization_onboarding.update(onboarding_params)
      redirect_to organization_onboarding_gems_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def onboarding_params
    params.require(:organization_onboarding).permit(:organization_name, :organization_handle)
  end
end
