module UsersHelper
  def twitter_username(user)
    "@#{user.twitter_username}" if user.twitter_username.present?
  end

  def twitter_url(user)
    "https://twitter.com/#{user.twitter_username}"
  end

  def mastodon_handle(user)
    "@#{user.mastodon_handle}" if user.mastodon_handle.present?
  end

  def mastodon_url(user)
    "@#{user.mastodon_handle}"
  end
end
