class OwnershipsController < ApplicationController
  before_filter :redirect_to_root, :only => [:index, :create], :unless => :signed_in?
  before_filter :find_rubygem, :only => [:index, :create]
  before_filter :load_gem, :only => [:index, :create]

  def index
  end

  def create
    if owner = User.find_by_email(params[:email])
      @rubygem.ownerships.create(:user => owner)
      flash[:notice] = 'Owner added successfully.'
    else
      flash[:warning] = "Owner could not be found."
    end
    redirect_to rubygem_ownerships_path(@rubygem)
  end

protected

  def load_gem
    if !@rubygem.owned_by?(current_user)
      flash[:warning] = "You do not have permission to edit this gem."
      redirect_to root_url
    end

    @linkset = @rubygem.linkset
  end
end
