class Organizations::OnboardingController < Organizations::Onboarding::BaseController
  def index
    redirect_to organization_onboarding_name_path
  end

  def destroy
    if @organization_onboarding.completed?
      flash[:error] = "Cannot destroy a completed onboarding"
    elsif @organization_onboarding.persisted?
      @organization_onboarding.destroy
    end

    redirect_to dashboard_path
  end
end
