class Onboarding::UsersController < Onboarding::BaseController
  layout "onboarding"

  def edit
    @roles = Membership.roles.map { |k, _| [Membership.human_attribute_name("role.#{k}"), k] }
  end

  def update
    if @organization_onboarding.update(onboarding_user_params)
      redirect_to onboarding_confirm_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def invites
    @invites = @organization_onboarding.user_invites
  end
  helper_method :invites

  def onboarding_user_params
    params.require(:organization_onboarding).permit(invites_attributes: %i[id user_id role])
  end
end
