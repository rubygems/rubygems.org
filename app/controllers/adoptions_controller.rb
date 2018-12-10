class AdoptionsController < ApplicationController
  before_action :redirect_to_root, unless: :signed_in?, except: :index
  before_action :find_rubygem
  before_action :render_bad_request, unless: :user_is_owner?, only: %i[create destroy]

  def index
    @adoption = @rubygem.adoptions.first
    @user_adoption_request = current_user&.adoption_requests&.find_by(rubygem_id: @rubygem.id, status: :opened)
  end

  def create
    adoption = @rubygem.adoptions.build(adoption_params)

    if adoption.save
      redirect_to rubygem_adoptions_path(@rubygem), flash: { success: t(".success", gem: @rubygem.name) }
    else
      redirect_to rubygem_adoptions_path(@rubygem), flash: { error: adoption.errors.full_messages.to_sentence }
    end
  end

  def destroy
    adoption = Adoption.find(params[:id])
    if adoption.destroy
      redirect_to rubygem_adoptions_path(@rubygem), flash: { success: t(".success", gem: @rubygem.name) }
    else
      redirect_to rubygem_adoptions_path(@rubygem), flash: { error: adoption.errors.full_messages.to_sentence }
    end
  end

  private

  def adoption_params
    params.require(:adoption).permit(:note).merge(user_id: current_user.id)
  end

  def user_is_owner?
    @rubygem.owned_by?(current_user)
  end
end
