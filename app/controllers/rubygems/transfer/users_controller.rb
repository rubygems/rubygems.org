class Rubygems::Transfer::UsersController < Rubygems::Transfer::BaseController
  layout "onboarding"

  def edit
  end

  def update
    if @rubygem_transfer.update(rubygem_transfer_params)
      redirect_to confirm_transfer_rubygems_path
    else
      render :edit, status: :unprocessable_content
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
