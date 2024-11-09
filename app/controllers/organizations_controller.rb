class OrganizationsController < ApplicationController
  def show
    @organization = Organization.find_by(handle: params[:handle])
  end

  private

  def organization_params
  end
end
