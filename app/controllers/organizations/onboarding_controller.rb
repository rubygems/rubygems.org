class Organizations::OnboardingController < Organizations::BaseController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?

  def destroy
    OrganizationOnboarding.destroy_by(created_by: Current.user, status: %i[pending failed])

    redirect_to dashboard_path
  end
end
