class AdoptionsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?, except: :index
  before_action :find_rubygem, except: :index

  def index
  end

  def show
  end

  def new
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
  end

  private

  def adoption_params
    params.require(:adoption).permit(:note, :status).merge(user_id: current_user.id)
  end

  def create_adoption(message)
    @rubygem.adoptions.create(adoption_params)
    redirect_to rubygem_adoptions_path(@rubygem), flash: { success: message }
  end

  def render_bad_request
    render plain: "Invalid adoption request", status: :bad_request
  end
end
