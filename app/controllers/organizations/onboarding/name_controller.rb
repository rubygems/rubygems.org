class Organizations::Onboarding::NameController < Organizations::Onboarding::BaseController
  def new
  end

  def create
    if @organization_onboarding.update(onboarding_name_params)
      redirect_to organization_onboarding_gems_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def onboarding_name_params
    params.expect(organization_onboarding: %i[organization_name organization_handle])
  end
end
