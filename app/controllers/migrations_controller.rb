class MigrationsController < ApplicationController
  before_filter :authenticate_with_api_key, :only => :create
  rescue_from ActiveRecord::RecordNotFound, :with => lambda {
    render :text => "This gem could not be found.", :status => :not_found
  }

  def create
    @rubygem = Rubygem.find(params[:rubygem_id])

    if @rubygem.unowned?
      ownership = @rubygem.ownerships.find_or_create_by_user_id(current_user.id)
      render :text => ownership.token
    else
      render :text => "This gem has already been migrated by another user.", :status => :forbidden
    end
  end
end
