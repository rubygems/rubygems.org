class OrganizationsController < ApplicationController
  def show
    render plain: flash[:notice] # HACK: for tests until this view is ready
  end

  private

  def organization_params
  end
end
