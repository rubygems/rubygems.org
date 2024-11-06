class Onboarding::UsersController < Onboarding::BaseController
  layout "onboarding"

  def edit
    initialize_roles
  end

  def update
    if @organization_onboarding.update(onboarding_user_params)
      redirect_to onboarding_confirm_path
    else
      initialize_roles
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def initialize_roles
    @roles = Membership.roles.map { |k, _| [Membership.human_attribute_name("role.#{k}"), k] }
  end

  def onboarding_user_params
    params.require(:organization_onboarding).permit(invites_attributes: %i[id user_id role])
  end
end
