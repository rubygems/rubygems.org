class AvatarsController < ApplicationController
  before_action :find_user
  before_action :set_size
  before_action :set_theme

  def show
    gravatar_url = @user.gravatar_url(size: @size, default: "404", secure: true)

    resp = gravatar_client
      .get(gravatar_url, nil,
           { "Accept" => "image/png", "Connection" => "close", "User-Agent" => "RubyGems.org avatar proxy" })

    if resp.success?
      fastly_expires_in(5.minutes)

      # don't copy other headers, since they might leak user info
      response.headers["last-modified"] = resp.headers["last-modified"] if resp.headers["last-modified"]
      filename = "#{@user.display_id}_avatar_#{@size}.#{params[:format]}"
      send_data(resp.body, type: resp.headers["content-type"], disposition: "inline", filename:)
    elsif resp.status == 404
      fastly_expires_in(5.minutes)

      # means gravatar doesn't have an avatar for this user
      # we'll just redirect to our default avatar instead, so everything is cachable
      redirect_to default_avatar_url
    else
      # any other error, just redirect to our default avatar
      # this includes 400, 429, 500s, etc
      logger.warn(message: "Failed to fetch gravatar", status: resp.status, url: gravatar_url, user_id: @user.id)
      redirect_to default_avatar_url
    end
  end

  private

  def find_user
    @user = User.find_by_slug(params[:id])
    return if @user
    render_not_found
  end

  def set_size
    @size = params.permit(:size).fetch(:size, 64).to_i
    return unless @size < 1 || @size > 2048
    render plain: "Invalid size", status: :bad_request
  end

  def set_theme
    @theme = params.permit(:theme).fetch(:theme, "light")
    return if %w[light dark].include?(@theme)
    render plain: "Invalid theme", status: :bad_request
  end

  def default_avatar_url
    case @theme
    when "light" then "/images/avatar.svg"
    when "dark" then "/images/avatar_inverted.svg"
    else raise "invalid default avatar theme, only light and dark are suported"
    end
  end

  def gravatar_client
    Faraday.new(nil, request: { timeout: 2 }) do |f|
      f.response :logger, logger, headers: false, errors: true
    end
  end
end
