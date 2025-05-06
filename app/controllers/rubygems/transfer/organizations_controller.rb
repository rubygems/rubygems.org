class Rubygems::Transfer::OrganizationsController < Rubygems::Transfer::BaseController
  rescue_from ActiveRecord::RecordNotFound, with: -> { redirect_to dashboard_path }

  layout "onboarding"

  def new
    @organizations = Current.user.organizations
  end

  def create
    selected_org = Organization.find_by(handle: params[:rubygem_transfer][:organization_handle])

    @rubygem_transfer.transferable = selected_org
    @rubygem_transfer.save!

    redirect_to rubygem_transfer_users_path(@rubygem.slug)
  end
end
