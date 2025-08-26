module UsersHelper
  def social_link(user)
    user.social_link.presence
  end

  def show_policies_acknowledge_banner?(user)
    user.present? && !user.policies_acknowledged?
  end
end
