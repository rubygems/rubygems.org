class AdoptionsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?, except: :index
  before_action :find_rubygem
  before_action :find_adoption, only: :destroy

  def index
    @adoption = @rubygem.adoptions.first
    @user_adoption_request = current_user&.adoption_requests&.find_by(rubygem_id: @rubygem.id, status: :opened)
  end

  def create
    if @rubygem.owned_by?(current_user)
      @rubygem.adoptions.create(adoption_params)
      redirect_to rubygem_adoptions_path(@rubygem), flash: { success: t(".success", gem: @rubygem.name) }
    else
      render_bad_request
    end
  end

  def destroy
    if @rubygem.owned_by? current_user
      @adoption.destroy
      redirect_to rubygem_adoptions_path(@rubygem), flash: { success: t(".success", gem: @rubygem.name) }
    else
      render_bad_request
    end
  end

  private

  def adoption_params
    params.require(:adoption).permit(:note).merge(user_id: current_user.id)
  end

  def find_adoption
    @adoption = Adoption.find(params[:id])
  end

  def render_bad_request
    render plain: "Invalid adoption request", status: :bad_request
  end
end
