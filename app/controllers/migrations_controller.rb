class MigrationsController < ApplicationController
  before_filter :authenticate_with_api_key, :only => :create
  rescue_from ActiveRecord::RecordNotFound, :with => lambda {
    render :text => "This gem could not be found.", :status => :not_found
  }

  def create
    @rubygem = Rubygem.find(params[:rubygem_id])

    if @rubygem.unowned?
      ownership = @rubygem.ownerships.create(:user => current_user)
      ownership.send_later(:check_for_upload)
      render :text => ownership.token
    else
      render :text => "This gem has already been migrated by another user.", :status => :forbidden
    end
  end
end
