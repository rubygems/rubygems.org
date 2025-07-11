module UsersHelper
  def show_policies_acknowledge_banner?(user)
    user.present? && !user.policies_acknowledged?
  end
end
