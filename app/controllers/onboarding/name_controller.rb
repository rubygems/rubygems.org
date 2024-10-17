class Onboarding::NameController < ApplicationController
  before_action :redirect_to_signin, unless: :signed_in?
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?
  
  def new
    @onboarding = OrganizationOnboarding.find_or_initialize_by(created_by: current_user, status: :pending)
  end

  def create
    redirect_to edit_onboarding_gems_path
  end

  def update
  end

  private

  def onboarding_params
    params.require(:organization_onboarding).permit(:name, :description, :industry)
  end
end