class Organizations::Onboarding::ConfirmController < Organizations::Onboarding::BaseController
  def edit
  end

  def update
    @organization_onboarding.onboard!

    flash[:notice] = I18n.t("organization_onboardings.confirm.success")
    redirect_to organization_path(@organization_onboarding.organization)
  rescue ActiveRecord::ActiveRecordError
    flash.now[:error] = "Onboarding error: #{@organization_onboarding.error}"
    render :edit, status: :unprocessable_entity
  end
end
