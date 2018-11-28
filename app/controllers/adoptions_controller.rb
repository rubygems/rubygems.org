class AdoptionsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?, except: :index
  before_action :find_adoption, only: %i[show update]
  before_action :find_adoption_user, only: :update
  before_action :find_rubygem

  def index
    @opened_adoption = @rubygem.adoptions.opened.first
    @user_requested_adoption = current_user&.adoptions&.find_by(rubygem_id: @rubygem.id, status: :requested)
  end

  def create
    if params[:adoption][:status] == "opened" && @rubygem.owned_by?(current_user)
      create_adoption "#{@rubygem.name} has been put up for adoption"
    elsif params[:adoption][:status] == "requested"
      create_adoption "Adoption request sent to owner of #{@rubygem.name}"
      Mailer.delay.adoption_requested(@adoption)
    else
      render_bad_request
    end
  end

  def update
    if params[:adoption][:status] == "approved" && @rubygem.owned_by?(current_user)
      @rubygem.approve_adoption!(@adoption)
      Mailer.delay.adoption_approved(@rubygem, @adoption_user)

      redirect_to_adoptions_path
    elsif params[:adoption][:status] == "canceled" && current_user.can_cancel?(@adoption)
      @adoption.canceled!
      Mailer.delay.adoption_canceled(@rubygem, @adoption_user) unless @adoption.user_id == current_user.id

      redirect_to_adoptions_path
    else
      render_bad_request
    end
  end

  private

  def adoption_params
    params.require(:adoption).permit(:note, :status).merge(user_id: current_user.id)
  end

  def create_adoption(message)
    @adoption = @rubygem.adoptions.create(adoption_params)
    redirect_to rubygem_adoptions_path(@rubygem), flash: { success: message }
  end

  def redirect_to_adoptions_path
    message = "#{@adoption_user.name}'s adoption request for #{@rubygem.name} has been #{@adoption.status}"
    redirect_to rubygem_adoptions_path(@rubygem), flash: { success: message }
  end

  def render_bad_request
    render plain: "Invalid adoption request", status: :bad_request
  end

  def find_adoption_user
    @adoption_user = User.find(@adoption.user_id)
  end

  def find_adoption
    @adoption = Adoption.find(params[:id])
  end
end
