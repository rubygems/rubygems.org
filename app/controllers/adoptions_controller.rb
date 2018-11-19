class AdoptionsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?, except: :index
  before_action :find_adoption, only: %i[show update]
  before_action :find_rubygem

  def index
    @user_adoption = current_user&.adoptions&.find_by(rubygem_id: @rubygem.id)
    @adoption = @rubygem.adoptions.seeked
  end

  def create
    if params[:adoption][:status] == "seeked" && @rubygem.owned_by?(current_user)
      create_adoption "#{@rubygem.name} has been put up for adoption"
    elsif params[:adoption][:status] == "requested"
      create_adoption "Adoption request sent to owner of #{@rubygem.name}"
    else
      render_bad_request
    end
  end

  def update
    @adoption_user = User.find(@adoption.user_id)
    if params[:status] == "approved" && @rubygem.owned_by?(current_user)
      @rubygem.ownerships.create(user: @adoption_user)
      update_adoption "#{@adoption_user.name}'s adoption request for #{@rubygem.name} has been approved"
    elsif params[:status] == "canceled" && current_user.can_cancel?(@adoption)
      update_adoption "#{@adoption_user.name}'s adoption request for #{@rubygem.name} has been canceled"
    else
      render_bad_request
    end
  end

  private

  def adoption_params
    params.require(:adoption).permit(:note, :status).merge(user_id: current_user.id)
  end

  def create_adoption(message)
    @rubygem.adoptions.create(adoption_params)
    redirect_to rubygem_adoptions_path(@rubygem), flash: { success: message }
  end

  def update_adoption(message)
    @adoption.update(status: params[:status])
    redirect_to rubygem_adoptions_path(@rubygem), flash: { success: message }
  end

  def render_bad_request
    render plain: "Invalid adoption request", status: :bad_request
  end

  def find_adoption
    @adoption = Adoption.find(params[:id])
  end
end
