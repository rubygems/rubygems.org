class Organizations::Onboarding::UsersController < Organizations::Onboarding::BaseController
  def edit
  end

  def update
    if @organization_onboarding.update(onboarding_user_params)
      redirect_to organization_onboarding_confirm_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def role_options
    @role_options ||= OrganizationOnboardingInvite.roles.map do |k, _|
      [Membership.human_attribute_name("role.#{k}"), k]
    end
  end
  helper_method :role_options

  def onboarding_user_params
    params.expect(organization_onboarding: [invites_attributes: [%i[id role]]])
  end
end
