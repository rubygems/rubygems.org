class Api::V1::ApiKeysController < Api::BaseController
  include ApiKeyable

  def show
    authenticate_or_request_with_http_basic do |username, password|
      # strip username mainly to remove null bytes
      user = User.authenticate(username.strip, password)
      check_mfa(user) do
        key = generate_unique_rubygems_key
        api_key = user.api_keys.build(legacy_key_defaults.merge(hashed_key: hashed_key(key)))

        save_and_respond(api_key, key)
      end
    end
  end

  def create
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username, password)

      check_mfa(user) do
        key = generate_unique_rubygems_key
        api_key = user.api_keys.build(api_key_create_params.merge(hashed_key: hashed_key(key)))

        save_and_respond(api_key, key)
      end
    end
  end

  def update
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username, password)

      check_mfa(user) do
        api_key = user.api_keys.find_by!(hashed_key: hashed_key(params[:api_key]))

        if api_key.update(api_key_update_params)
          respond_with "Scopes for the API key #{api_key.name} updated"
        else
          errors = api_key.errors.full_messages
          respond_with "Failed to update scopes for the API key #{api_key.name}: #{errors}", status: :unprocessable_entity
        end
      end
    end
  end

  private

  def check_mfa(user)
    if user&.mfa_gem_signin_authorized?(otp)
      return render_mfa_setup_required_error if user.mfa_required_not_yet_enabled?
      return render_mfa_strong_level_required_error if user.mfa_required_weak_level_enabled?

      yield
    elsif user&.mfa_enabled?
      prompt_text = otp.present? ? t(:otp_incorrect) : t(:otp_missing)
      render plain: prompt_text, status: :unauthorized
    else
      false
    end
  end

  def save_and_respond(api_key, key)
    if api_key.save
      Mailer.delay.api_key_created(api_key.id)
      respond_with key
    else
      respond_with api_key.errors.full_messages.to_sentence, status: :unprocessable_entity
    end
  end

  def respond_with(msg, status: :ok)
    respond_to do |format|
      format.any(:all) { render plain: msg, status: status }
      format.json { render json: { rubygems_api_key: msg, status: status } }
      format.yaml { render plain: { rubygems_api_key: msg, status: status }.to_yaml }
    end
  end

  def otp
    request.headers["HTTP_OTP"]
  end

  def api_key_create_params
    params.permit(:name, *ApiKey::API_SCOPES, :mfa)
  end

  def api_key_update_params
    params.permit(*ApiKey::API_SCOPES, :mfa)
  end
end
