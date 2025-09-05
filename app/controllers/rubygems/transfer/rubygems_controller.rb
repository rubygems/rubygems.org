class Rubygems::Transfer::RubygemsController < Rubygems::Transfer::BaseController
  layout "onboarding"

  def show
  end

  def update
    if @rubygem_transfer.update(rubygem_transfer_params)
      redirect_to users_transfer_rubygems_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def rubygem_transfer_params
    params.permit(rubygem_transfer: { rubygems: [] }).fetch(:rubygem_transfer, {})
  end
end
