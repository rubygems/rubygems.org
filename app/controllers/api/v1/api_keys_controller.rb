# frozen_string_literal: true

class Api::V1::ApiKeysController < Api::BaseController
  include ApiKeyable

  before_action :deny_shared_cache

  def show
    render plain: "This endpoint has been retired. `gem signin` (GET /api/v1/api_key) is no " \
                  "longer supported. Create an API key at https://rubygems.org/profile/api_keys " \
                  "and set it up following https://guides.rubygems.org/api-key-scopes/.",
      status: :gone
  end

  def create
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username, password)
      track_appsec_login_failure(actor: nil, login: username, authentication_method: "password") unless user

      check_mfa(user) do
        key = generate_unique_rubygems_key
        build_params = { owner: user, hashed_key: hashed_key(key), **api_key_create_params }
        api_key = ApiKey.new(build_params)

        save_and_respond(api_key, key)
      end
    end
  end

  def update
    authenticate_or_request_with_http_basic do |username, password|
      user = User.authenticate(username, password)
      track_appsec_login_failure(actor: nil, login: username, authentication_method: "password") unless user

      check_mfa(user) do
        api_key = user.api_keys.find_by!(hashed_key: hashed_key(key_param))

        if api_key.update(api_key_update_params(api_key))
          track_api_key_event("api_key.update", api_key)
          respond_with "Scopes for the API key #{api_key.name} updated"
        else
          errors = api_key.errors.full_messages
          respond_with "Failed to update scopes for the API key #{api_key.name}: #{errors}", status: :unprocessable_content
        end
      end
    end
  end

  private

  def check_mfa(user)
    return false unless user
    return render_forbidden t(:email_not_confirmed) if user.unconfirmed?

    if user.mfa_gem_signin_authorized?(otp)
      Current.user = user
      return render_forbidden t("multifactor_auths.api.mfa_required_not_yet_enabled").chomp if user.mfa_required_not_yet_enabled?
      return render_forbidden t("multifactor_auths.api.mfa_required_weak_level_enabled").chomp if user.mfa_required_weak_level_enabled?

      track_appsec_login_success(actor: user)
      yield
    elsif user.mfa_enabled?
      track_appsec_login_failure(actor: user, authentication_method: "password", reason: otp.present? ? "invalid_otp" : "missing_otp")
      prompt_text = otp.present? ? t(:otp_incorrect) : t(:otp_missing)
      render plain: prompt_text, status: :unauthorized
    else
      false
    end
  end

  def save_and_respond(api_key, key)
    if api_key.errors.blank? && api_key.save
      track_api_key_event("api_key.create", api_key)
      Mailer.api_key_created(api_key.id).deliver_later
      respond_with key
    else
      respond_with api_key.errors.full_messages.to_sentence, status: :unprocessable_content
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

  def key_param
    params.expect(:api_key)
  end

  def api_key_create_params
    ApiKeysHelper.api_key_params(params.permit(:name, *ApiKey::API_SCOPES, :mfa, :rubygem_name, :expires_at, scopes: [ApiKey::API_SCOPES]))
  end

  def api_key_update_params(key)
    ApiKeysHelper.api_key_params(params.permit(*ApiKey::API_SCOPES, :mfa, scopes: [ApiKey::API_SCOPES]), key)
  end
end
