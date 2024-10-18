class Onboarding::GemsController < BaseController
  def edit
  end

  def update
    redirect_to edit_onboarding_users_path
  end
end