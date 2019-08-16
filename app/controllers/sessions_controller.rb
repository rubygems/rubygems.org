class SessionsController < Clearance::SessionsController
  def create
    @user = find_user(params.require(:session))

    if @user&.webauthn_enabled?
      session[:mfa_user] = @user.handle
      render "sessions/webauthn_prompt"
    elsif @user&.mfa_enabled?
      session[:mfa_user] = @user.handle
      render "sessions/otp_prompt"
    else
      do_login
    end
  end

  def mfa_create
    @user = User.find_by_name(session[:mfa_user])
    session.delete(:mfa_user)

    if @user&.mfa_enabled? && @user&.otp_verified?(params[:otp])
      do_login
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  end

  def webauthn_authentication_options
    user = User.find_by_name(session[:mfa_user])

    if user&.webauthn_enabled?
      credentials_request_options = WebAuthn.credential_request_options
      credentials_request_options[:allowCredentials] = user.credentials.map do |cred|
        { id: cred.external_id, type: "public-key" }
      end

      credentials_request_options[:challenge] = bin_to_str(credentials_request_options[:challenge])
      session[:webauthn_challenge] = credentials_request_options[:challenge]

      respond_to do |format|
        format.json { render json: credentials_request_options }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: ["Unprocessable request"] }, status: :unprocessable_entity }
      end
    end
  end

  def webauthn_authentication
    @user = User.find_by_name(session[:mfa_user])
    session.delete(:mfa_user)

    public_key_credential = WebAuthn::PublicKeyCredential.from_get(params, encoding: :base64url)
    current_challenge = session[:webauthn_challenge]

    if @user&.webauthn_enabled? && @user&.webauthn_verified?(current_challenge, public_key_credential)
      sign_in(@user) do |status|
        if status.success?
          render json: { status: "ok", redirect_path: "/" }, status: :ok
        else
          login_failure(status.failure_message)
        end
      end
    else
      login_failure(t("webauthn_credentials.incorrect_credentials"))
    end
  end

  private

  def do_login
    sign_in(@user) do |status|
      if status.success?
        StatsD.increment "login.success"
        redirect_back_or(url_after_create)
      else
        login_failure(status.failure_message)
      end
    end
  end

  def login_failure(message)
    StatsD.increment "login.failure"
    flash.now.notice = message
    render template: "sessions/new", status: :unauthorized
  end

  def find_user(session)
    who = session[:who].is_a?(String) && session.fetch(:who)
    password = session[:password].is_a?(String) && session.fetch(:password)

    User.authenticate(who, password) if who && password
  end

  def url_after_create
    dashboard_path
  end
end
