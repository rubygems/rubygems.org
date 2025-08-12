class GemPermissions
  def initialize(rubygem, user)
    @rubygem = rubygem
    @user = user
  end

  def can_push?
    return false if user.blank?

    if rubygem.owned_by_organization?
      org_member_in_role?(:maintainer) || user_in_role?(:maintainer)
    else
      user_in_role?(:maintainer)
    end
  end

  def can_manage_owners?
    role_granted?(:owner)
  end

  def can_perform_gem_admin?
    role_granted?(:admin)
  end

  private

  attr_reader :rubygem, :user

  def role_granted?(minimum_role)
    return false if @user.blank?

    if rubygem.owned_by_organization?
      org_member_in_role?(minimum_role)
    else
      user_in_role?(minimum_role)
    end
  end

  def org_member_in_role?(minimum_role)
    case minimum_role
    when :maintainer
      rubygem.organization.user_is_member?(user)
    when :admin
      rubygem.organization.administered_by?(user)
    when :owner
      rubygem.organization.owned_by?(user)
    else
      false
    end
  end

  def user_in_role?(minimum_role)
    rubygem.ownerships.user_with_minimum_role(user, minimum_role).exists?
  end
end
