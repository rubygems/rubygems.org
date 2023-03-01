class SessionsController < Clearance::SessionsController
  include MfaExpiryMethods
  include PrivacyPassSupportable

  before_action :redirect_to_signin, unless: :signed_in?, only: %i[verify authenticate]
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, only: %i[verify authenticate]
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, only: %i[verify authenticate]
  before_action :ensure_not_blocked, only: :create
  after_action :delete_mfa_expiry_session, only: %i[webauthn_create mfa_create]

  def new
    if request.headers["Authorization"] && redeem_privacy_pass_token
      super
    else
      setup_privacy_pass_challenge
      render "sessions/new", status: :unauthorized
    end
  end

  def create
    @user = find_user
    if !session[:redeemed_privacy_pass] && HcaptchaVerifier.should_verify_sign_in?(who)
      setup_captcha_verification
      render "sessions/captcha"
    elsif @user && (@user.mfa_enabled? || @user.webauthn_credentials.any?)
      webauthn_and_mfa_new
    else
      do_login
    end
  end

  def webauthn_create
    @user = User.find(session.dig(:webauthn_authentication, "user"))
    @challenge = session.dig(:webauthn_authentication, "challenge")

    if params[:credentials].blank?
      webauthn_verification_failure(t("credentials_required"))
      return
    elsif !session_active?
      webauthn_verification_failure(t("multifactor_auths.session_expired"))
      return
    end

    @credential = WebAuthn::Credential.from_get(params[:credentials])

    @webauthn_credential = @user.webauthn_credentials.find_by(
      external_id: @credential.id
    )

    @credential.verify(
      @challenge,
      public_key: @webauthn_credential.public_key,
      sign_count: @webauthn_credential.sign_count
    )

    @webauthn_credential.update!(sign_count: @credential.sign_count)

    record_mfa_login_duration(mfa_type: "webauthn")

    do_login
  rescue WebAuthn::Error => e
    webauthn_verification_failure(e.message)
  ensure
    session.delete(:webauthn_authentication)
    session.delete(:mfa_login_started_at)
  end

  def mfa_create
    @user = User.find(session[:mfa_user])
    session.delete(:mfa_user)

    if login_conditions_met?
      record_mfa_login_duration(mfa_type: "otp")

      do_login
    elsif !session_active?
      login_failure(t("multifactor_auths.session_expired"))
    else
      login_failure(t("multifactor_auths.incorrect_otp"))
    end
  ensure
    session.delete(:mfa_login_started_at)
  end

  def captcha_create
    @user = User.find(session[:captcha_user])
    session.delete(:captcha_user)

    captcha_success = HcaptchaVerifier.call(captcha_response, request.remote_ip)
    should_mfa = @user && (@user.mfa_enabled? || @user.webauthn_credentials.any?)
    if captcha_success
      should_mfa ? webauthn_and_mfa_new : do_login
    else
      login_failure(t("captcha.invalid"))
    end
  end

  def verify
  end

  def authenticate
    if verify_user
      session[:verified_user] = current_user.id
      session[:verification]  = Time.current + Gemcutter::PASSWORD_VERIFICATION_EXPIRY
      redirect_to session.delete(:redirect_uri) || root_path
    else
      flash.now[:alert] = t("profiles.request_denied")
      render :verify, status: :unauthorized
    end
  end

  private

  def verify_user
    current_user.authenticated? verify_password_params[:password]
  end

  def verify_password_params
    params.require(:verify_password).permit(:password)
  end

  def webauthn_and_mfa_new
    setup_webauthn_authentication
    setup_mfa_authentication

    session[:mfa_login_started_at] = Time.now.utc.to_s
    create_new_mfa_expiry

    render "sessions/prompt"
  end

  def do_login
    sign_in(@user) do |status|
      if status.success?
        StatsD.increment "login.success"
        session.delete(:redeemed_privacy_pass)
        redirect_back_or(url_after_create)
      else
        login_failure(status.failure_message)
      end
    end
  end

  def login_failure(message)
    StatsD.increment "login.failure"
    flash.now.notice = message
    render "sessions/new", status: :unauthorized
  end

  def webauthn_verification_failure(message = nil)
    flash.now.notice = message
    render "sessions/prompt", status: :unauthorized
  end

  def session_params
    params.require(:session)
  end

  def captcha_response
    params.permit("h-captcha-response")["h-captcha-response"]
  end

  def find_user
    password = session_params[:password].is_a?(String) && session_params.fetch(:password)

    User.authenticate(who, password) if who && password
  end

  def who
    session_params[:who].is_a?(String) && session_params.fetch(:who)
  end

  def url_after_create
    if current_user.mfa_recommended_not_yet_enabled?
      flash[:notice] = t("multifactor_auths.setup_recommended")
      new_multifactor_auth_path
    elsif current_user.mfa_recommended_weak_level_enabled?
      flash[:notice] = t("multifactor_auths.strong_mfa_level_recommended")
      edit_settings_path
    else
      dashboard_path
    end
  end

  def ensure_not_blocked
    user = User.find_by_blocked(who)
    return unless user&.blocked_email

    flash.now.alert = t(".account_blocked")
    render template: "sessions/new", status: :unauthorized
  end

  def setup_webauthn_authentication
    return if @user.webauthn_credentials.none?

    @webauthn_options = @user.webauthn_options_for_get

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge,
      "user" => @user.id
    }
  end

  def setup_mfa_authentication
    return if @user.mfa_disabled?
    session[:mfa_user] = @user.id
  end

  def setup_captcha_verification
    session[:captcha_user] = @user.id
  end

  def setup_privacy_pass_challenge
    tokenizer = PrivacyPassTokenizer.new
    tokenizer.register_challenge_for_redemption(session.id)
    challenge = tokenizer.challenge_token
    response.set_header("WWW-Authenticate", "PrivateToken challenge=#{challenge}, token-key=#{PrivacyPassTokenizer.issuer_public_key}")
  end

  def redeem_privacy_pass_token
    PrivacyPassRedeemer.call(request.headers["Authorization"], session.id)
  end

  def login_conditions_met?
    @user&.mfa_enabled? && @user&.otp_verified?(params[:otp]) && session_active?
  end

  def record_mfa_login_duration(mfa_type:)
    started_at = Time.zone.parse(session[:mfa_login_started_at]).utc
    duration = Time.now.utc - started_at

    StatsD.distribution("login.mfa.#{mfa_type}.duration", duration)
  end
end
