# frozen_string_literal: true

class Rubygems::Transfer::UsersController < Rubygems::Transfer::BaseController
  layout "onboarding"

  def edit
    authorize @rubygem_transfer.organization, :add_gem?
  end

  def update
    authorize @rubygem_transfer.organization, :add_gem?

    if @rubygem_transfer.update(rubygem_transfer_params)
      redirect_to confirm_transfer_rubygems_path
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def role_options
    @role_options ||= OrganizationInvite.roles.then do |roles|
      owner_membership = @rubygem_transfer.organization.memberships.build(role: :owner)
      roles = roles.except("owner") unless policy(owner_membership).create?

      roles.map do |role, _|
        [Membership.human_attribute_name("role.#{role}"), role]
      end
    end
  end
  helper_method :role_options

  def rubygem_transfer_params
    params.fetch(:rubygem_transfer, {}).permit(invites_attributes: [%i[id role]])
  end
end
