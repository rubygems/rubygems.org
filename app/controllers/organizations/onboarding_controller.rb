class Organizations::OnboardingController < Organizations::BaseController
  def destroy
    OrganizationOnboarding.destroy_by(created_by: Current.user, status: %i[pending failed])

    redirect_to dashboard_path
  end
end
