class OnboardingController < Onboarding::BaseController
  def index
  end

  def create
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
