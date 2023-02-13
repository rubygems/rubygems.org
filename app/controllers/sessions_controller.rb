class SessionsController < Clearance::SessionsController
  before_action :redirect_to_signin, unless: :signed_in?, only: %i[verify authenticate]
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, only: %i[verify authenticate]
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, only: %i[verify authenticate]
  before_action :ensure_not_blocked, only: :create

  def create
    @user = find_user

    if @user && (@user.mfa_enabled? || @user.webauthn_credentials.any?)
      setup_webauthn_authentication
      setup_mfa_authentication

      session[:mfa_login_started_at] = Time.now.utc.to_s
      session[:mfa_expires_at] = 15.minutes.from_now.to_s

      render "sessions/prompt"
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
    session.delete(:mfa_expires_at)
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
    session.delete(:mfa_expires_at)
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
    render "sessions/new", status: :unauthorized
  end

  def webauthn_verification_failure(message = nil)
    flash.now.notice = message
    render "sessions/prompt", status: :unauthorized
  end

  def session_params
    params.require(:session)
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

  def session_active?
    return false if session[:mfa_expires_at].nil?
    session[:mfa_expires_at] > Time.current
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
