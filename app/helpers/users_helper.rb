module UsersHelper
  def twitter_username(user)
    "@#{user.twitter_username}" if user.twitter_username.present?
  end

  def twitter_url(user)
    "https://twitter.com/#{user.twitter_username}"
  end

  def show_policies_acknowledge_banner?(user)
    user.present? && !user.policies_acknowledged?
  end
end
