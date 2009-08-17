class MigrationsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_with_api_key
  before_filter :find_rubygem
  rescue_from ActiveRecord::RecordNotFound, :with => lambda {
    render :text => "This gem could not be found.", :status => :not_found
  }

  def create
    if @rubygem.unowned?
      ownership = @rubygem.ownerships.find_or_create_by_user_id(current_user.id)
      render :text => ownership.token
    else
      render :text => "This gem has already been migrated by another user.", :status => :forbidden
    end
  end

  def update
    ownership = @rubygem.ownerships.find_by_user_id(current_user.id)
    if ownership
      if ownership.migrated?
        render :text => "Your gem has been migrated! You can now push new versions with: `gem push #{@rubygem.name}`", :status => :created
      else
        render :text => "Gemcutter is still looking for your migration token.", :status => :accepted
      end
    else
      render :text => "You must create a migration token first", :status => :forbidden
    end

  end

  protected
    def find_rubygem
      @rubygem = Rubygem.find_by_name!(params[:rubygem_id])
    end
end
