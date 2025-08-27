class Rubygems::Transfer::ConfirmationsController < Rubygems::Transfer::BaseController
  layout "onboarding"
  before_action :ensure_valid_transfer

  def edit
    authorize @rubygem_transfer.organization, :add_gem?
  end

  def update
    authorize @rubygem_transfer.organization, :add_gem?

    @rubygem_transfer.transfer!

    flash[:notice] = I18n.t("rubygems.transfer.confirm.success",
                            organization: @rubygem_transfer.organization.name,
                            count: @rubygem_transfer.rubygems.size)
    redirect_to organization_path(@rubygem_transfer.organization.handle)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "Onboarding error: #{@rubygem_transfer.error}"
    render :edit, status: :unprocessable_content
  end

  private

  # This is a quick sanity check to ensure we have a ready RubygemTransfer. If the
  # transfer doesn't have an associated Organization, check the user authorization
  # would raise a Pundit::NilClassPolicy
  def ensure_valid_transfer
    return if @rubygem_transfer.organization.present? && @rubygem_transfer.rubygems.any?

    redirect_to organization_transfer_rubygems_path
  end
end
