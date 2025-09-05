class Rubygems::Transfer::OrganizationsController < Rubygems::Transfer::BaseController
  rescue_from ActiveRecord::RecordNotFound, with: -> { redirect_to dashboard_path }

  layout "onboarding"

  def new
    @organizations = current_user.organizations
  end

  def create
    @organizations = current_user.organizations
    @organization = @organizations.find_by(handle: organization_params[:rubygem_transfer][:organization])

    @rubygem_transfer.organization = @organization
    if @rubygem_transfer.save
      redirect_to rubygems_transfer_rubygems_path
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def organization_params
    params.permit(rubygem_transfer: [:organization])
  end
end
