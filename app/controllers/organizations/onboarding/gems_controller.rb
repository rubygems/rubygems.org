class Organizations::Onboarding::GemsController < Organizations::Onboarding::BaseController
  def edit
  end

  def update
    if @organization_onboarding.update(onboarding_gems_params)
      redirect_to organization_onboarding_users_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def onboarding_gems_params
    params.permit(organization_onboarding: { rubygems: [] }).fetch(:organization_onboarding, {})
  end
end
