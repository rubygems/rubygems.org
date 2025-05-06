class Rubygems::Transfer::ConfirmController < Rubygems::Transfer::BaseController
  layout "onboarding"

  def edit
  end

  def update
    @rubygem_transfer.transfer!

    flash[:notice] = I18n.t("organization_onboardings.confirm.success")
    redirect_to rubygem_path(@rubygem.slug)
  rescue ActiveRecord::ActiveRecordError
    flash.now[:error] = "Onboarding error: #{@organization_onboarding.error}"
    render :edit, status: :unprocessable_entity
  end
end
