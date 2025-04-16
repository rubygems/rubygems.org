class Api::V1::GitHubSecretScanningController < Api::BaseController
  include ApiKeyable

  before_action :find_secret_scanning_key
  before_action :validate_secret_scanning_key

  # API called by GitHub Secret Scanning tool
  # see docs https://docs.github.com/en/developers/overview/secret-scanning
  # Sample message:
  #
  # POST / HTTP/1.1
  # Host: HOST
  # Accept: */*
  # content-type: application/json
  # GITHUB-PUBLIC-KEY-IDENTIFIER: 90a421169f0a406205f1563a953312f0be898d3c7b6c06b681aa86a874555f4a
  # GITHUB-PUBLIC-KEY-SIGNATURE: MEUCICxTWEpKo7BorLKutFZDS6ie+YFg6ecU7kEA6rUUSJqsAiEA9bK0Iy6vk2QpZOOg2IpBhZ3JRVdwXx1zmgmNAR7Izpc=
  # Content-Length: 0000
  #
  # [{"token": "some_token", "type": "some_type", "url": "some_url"}]
  #
  def revoke
    tokens = params.expect(_json: [%i[token type url]]).index_by { |t| hashed_key(t.require(:token)) }
    api_keys = ApiKey.where(hashed_key: tokens.keys).index_by(&:hashed_key)
    resp = tokens.map do |hashed_key, t|
      api_key = api_keys[hashed_key]
      label = if api_key&.expire!
                schedule_revoke_email(api_key, t[:url])
                "true_positive"
              else
                "false_positive"
              end

      {
        token_raw: t[:token],
        token_type: t[:type],
        label: label
      }
    end

    respond_to do |format|
      format.json { render json: resp }
    end
  end

  private

  def find_secret_scanning_key
    if (key_id = request.headers.fetch("GITHUB-PUBLIC-KEY-IDENTIFIER", "").presence) &&
        (@signature = request.headers.fetch("GITHUB-PUBLIC-KEY-SIGNATURE", "").presence)
      @key = GitHubSecretScanning.new(key_id)
    elsif (key_id = request.headers.fetch("DepsDev-Public-Key-Identifier", "").presence) &&
        (@signature = request.headers.fetch("DepsDev-Public-Key-Signature", "").presence)
      @key = GitHubSecretScanning::DepsDev.new(key_id)
    else
      render plain: "Missing GitHub Signature", status: :unauthorized
    end
  end

  def validate_secret_scanning_key
    return render plain: "Can't fetch public key from GitHub", status: :unauthorized if @key.empty_public_key?
    body = request.body.read
    return if @key.valid_github_signature?(@signature, body)
    logger.warn "Invalid GitHub Signature", key: @key, signature: @signature, body: body
    render plain: "Invalid GitHub Signature", status: :unauthorized
  end

  def schedule_revoke_email(api_key, url)
    return unless api_key.user?
    Mailer.api_key_revoked(api_key.owner_id, api_key.name, api_key.scopes.join(", "), url).deliver_later
  end
end
