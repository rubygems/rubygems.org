module RoleHelper
  def role_options
    @role_options ||= OrganizationOnboardingInvite.roles.map do |k, _|
      [Membership.human_attribute_name("role.#{k}"), k]
    end
  end
end
