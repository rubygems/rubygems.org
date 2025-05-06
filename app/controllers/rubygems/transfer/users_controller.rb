class Rubygems::Transfer::UsersController < Rubygems::Transfer::BaseController
  layout "onboarding"

  def edit
    @users = @rubygem.owners
    @organization = @rubygem_transfer.transferable
  end

  def update
    if @rubygem_transfer.update(rubygem_transfer_params)
      redirect_to rubygem_transfer_confirm_path(@rubygem.slug)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def rubygem_transfer_params
    params.expect(rubygem_transfer: [invites_attributes: [%i[id role]]])
  end
end
