class Gravatar
  GRAVATAR_ENDPOINT = 'https://www.gravatar.com/avatar/'.freeze

  # A bogus Gravatar ID we can use to avoid leaking the email hash
  # of users that prefer to not have their emails disclosed.
  #
  # @see https://en.gravatar.com/site/implement/images/#default-image
  GRAVATAR_DEFAULT_ID = "00000000000000000000000000000000"

  # Default pixel demensions of a Gravatar image when none is specified
  DEFAULT_SIZE = 160

  def initialize(user, options = { size: DEFAULT_SIZE })
    @user = user
    @options = options
  end

  # Gravatar lowercases all emails—ensure we downcase any email
  # we want to look up to avoid missing potential matches.
  #
  # @return [String]
  def gravatar_id
    return GRAVATAR_DEFAULT_ID if @user.hide_email
    Digest::MD5.hexdigest(@user.email.to_s.downcase)
  end

  # Gravatar image request options
  #
  # @see https://en.gravatar.com/site/implement/images/#size
  # @see https://en.gravatar.com/site/implement/images/#rating
  # @see https://en.gravatar.com/site/implement/images/#default-image
  # @return [Hash]
  def gravatar_options
    {
      s: @options.fetch(:size),
      r: 'pg',
      d: 'retro'
    }
  end

  # @see https://en.gravatar.com/site/implement/images/#base-request
  # @return [String] A URL representing a well formed Gravatar image request endpoint
  def url
    "".concat(GRAVATAR_ENDPOINT, gravatar_id, '.png?', gravatar_options.to_query)
  end
end
