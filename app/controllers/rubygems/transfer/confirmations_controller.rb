class Rubygems::Transfer::ConfirmationsController < Rubygems::Transfer::BaseController
  layout "onboarding"

  def edit
    authorize @rubygem, :transfer_gem?
  end

  def update
    authorize @rubygem, :transfer_gem?

    @rubygem_transfer.transfer!

    flash[:notice] = I18n.t("rubygems.transfer.confirm.success", gem: @rubygem.name, organization: @rubygem_transfer.organization.name)
    redirect_to rubygem_path(@rubygem.slug)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "Onboarding error: #{@organization_onboarding.error}"
    render :edit, status: :unprocessable_entity
  end
end
