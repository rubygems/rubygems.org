class Onboarding::GemsController < Onboarding::BaseController
  def edit
    @avaliable_rubygems = @organization_onboarding.avaliable_rubygems
  end

  def update
    if @organization_onboarding.update(onboarding_gems_params)
      redirect_to onboarding_users_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def onboarding_gems_params
    params.require(:organization_onboarding).permit(rubygems: [])
  end
end
