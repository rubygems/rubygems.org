class Onboarding::NameController < Onboarding::BaseController
  def new
  end

  def create
    if @organization_onboarding.update(onboarding_params)
      redirect_to onboarding_gems_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def onboarding_params
    params.require(:organization_onboarding).permit(:title)
  end
end
