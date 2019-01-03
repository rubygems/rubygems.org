# frozen_string_literal: true

module UsersHelper
  def twitter_username(user)
    "@#{user.twitter_username}" if user.twitter_username.present?
  end

  def twitter_url(user)
    "https://twitter.com/#{user.twitter_username}"
  end
end
