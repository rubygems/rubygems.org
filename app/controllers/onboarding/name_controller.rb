class Onboarding::NameController < BaseController
  def new
  end

  def create
    redirect_to edit_onboarding_gems_path
  end

  private

  def onboarding_params
    params.require(:organization_onboarding).permit(:name, :description, :industry)
  end
end