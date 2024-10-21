class Onboarding::ConfirmController < Onboarding::BaseController
  def edit
  end

  def update
    if @organization_onboarding.onboard!
      render plain: "Organization succesfully onboarded!", status: :ok, location: root_path
    else
      render plain: "Organization could not be onboarded.", status: :unprocessable_entity
    end
  end
end
