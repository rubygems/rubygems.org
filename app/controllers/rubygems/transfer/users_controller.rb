class Rubygems::Transfer::UsersController < Rubygems::Transfer::BaseController
  layout "onboarding"

  def edit
    @users = @rubygem.owners
    @organization = @rubygem_transfer.organization
  end

  def update
    if @rubygem_transfer.update(rubygem_transfer_params)
      redirect_to rubygem_transfer_confirm_path(@rubygem.slug)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def role_options
    @role_options ||= OrganizationInvite.roles.map do |k, _|
      [Membership.human_attribute_name("role.#{k}"), k]
    end
  end
  helper_method :role_options

  def rubygem_transfer_params
    params.fetch(:rubygem_transfer, {}).permit(invites_attributes: [%i[id role]])
  end
end
