class Api::V1::GithubSecretScanningController < Api::BaseController
  include ApiKeyable

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
    key_id = request.headers.fetch("GITHUB-PUBLIC-KEY-IDENTIFIER", "")
    signature = request.headers.fetch("GITHUB-PUBLIC-KEY-SIGNATURE", "")

    return render plain: "Missing GitHub Signature", status: :unauthorized if key_id.blank? || signature.blank?
    key = secret_scanning_key(key_id)
    return render plain: "Can't fetch public key from GitHub", status: :unauthorized if key.empty_public_key?
    return render plain: "Invalid GitHub Signature", status: :unauthorized unless key.valid_github_signature?(signature, request.body.read.chomp)

    tokens = params.require(:_json).map { |t| t.permit(:token, :type, :url) }
    resp = []
    tokens.each do |t|
      api_key = ApiKey.find_by(hashed_key: t[:token])
      label = if api_key&.destroy
                Mailer.delay.api_key_revoked(api_key, t[:url])
                "true_positive"
              else
                "false_positive"
              end

      resp << {
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

  def secret_scanning_key(key_id)
    GithubSecretScanning.new(key_id)
  end
end
