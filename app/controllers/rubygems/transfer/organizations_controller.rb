class Rubygems::Transfer::OrganizationsController < Rubygems::Transfer::BaseController
  rescue_from ActiveRecord::RecordNotFound, with: -> { redirect_to dashboard_path }

  layout "onboarding"

  def new
  end

  def create
    @organizations = Current.user.organizations
    @organization = @organizations.find_by(handle: organization_params[:rubygem_transfer][:organization_handle])

    @rubygem_transfer.organization = @organization
    if @rubygem_transfer.save
      redirect_to rubygem_transfer_users_path(@rubygem.slug)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def organization_params
    params.permit(rubygem_transfer: [:organization_handle])
  end
end
