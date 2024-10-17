class Onboarding::UsersController < Onboarding::BaseController
  def edit
  end

  def update
    if @organization_onboarding.update!(onboarding_user_params)
      redirect_to onboarding_confirm_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def onboarding_user_params
    params.require(:organization_onboarding).permit(invitees: %i[id role])
  end
end
