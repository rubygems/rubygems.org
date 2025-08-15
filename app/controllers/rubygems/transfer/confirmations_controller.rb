class Rubygems::Transfer::ConfirmationsController < Rubygems::Transfer::BaseController
  layout "onboarding"

  def edit
    authorize @rubygem_transfer.organization, :add_gem?
  end

  def update
    authorize @rubygem_transfer.organization, :add_gem?

    @rubygem_transfer.transfer!

    flash[:notice] = I18n.t("rubygems.transfer.confirm.success", organization: @rubygem_transfer.organization.name)
    redirect_to organization_path(@rubygem_transfer.organization.handle)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "Onboarding error: #{@rubygem_transfer.error}"
    render :edit, status: :unprocessable_content
  end
end
