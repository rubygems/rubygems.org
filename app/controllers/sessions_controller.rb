class SessionsController < Clearance::SessionsController
  include MfaExpiryMethods
  include RequireMfa
  include WebauthnVerifiable
  include SessionVerifiable

  before_action :redirect_to_signin, unless: :signed_in?, only: %i[verify webauthn_authenticate authenticate]
  before_action :redirect_to_new_mfa, if: :mfa_required_not_yet_enabled?, only: %i[verify webauthn_authenticate authenticate]
  before_action :redirect_to_settings_strong_mfa_required, if: :mfa_required_weak_level_enabled?, only: %i[verify webauthn_authenticate authenticate]
  before_action :webauthn_new_setup, only: :new

  before_action :ensure_not_blocked, only: %i[create]
  before_action :find_mfa_user, only: %i[webauthn_create otp_create]
  before_action :validate_otp, only: %i[otp_create]
  before_action :validate_webauthn, only: %i[webauthn_create]
  after_action :delete_mfa_session, only: %i[webauthn_create webauthn_full_create otp_create]
  after_action :delete_session_verification, only: :destroy

  def create
    @user = find_user

    if @user&.mfa_enabled?
      initialize_mfa(@user)
      @otp_verification_url = otp_verification_url
      setup_webauthn_authentication(form_url: webauthn_verification_url)

      render "multifactor_auths/prompt"
    else
      do_login(two_factor_label: nil, two_factor_method: nil, authentication_method: "password")
    end
  end

  def webauthn_create
    record_mfa_login_duration(mfa_type: "webauthn")
    do_login(two_factor_label: user_webauthn_credential.nickname, two_factor_method: "webauthn", authentication_method: "password")
  end

  def webauthn_full_create
    return login_failure(@webauthn_error) unless webauthn_credential_verified?

    @user = user_webauthn_credential.user

    if @user.blocked_email
      flash.now.alert = t("sessions.create.account_blocked")
      webauthn_new_setup
      render template: "sessions/new", status: :unauthorized
    else
      do_login(two_factor_label: user_webauthn_credential.nickname, two_factor_method: nil, authentication_method: "webauthn")
    end
  end

  def otp_create
    record_mfa_login_duration(mfa_type: @mfa_method)
    do_login(two_factor_label: @mfa_label, two_factor_method: @mfa_method, authentication_method: "password")
  end

  def verify
    @user = current_user
    setup_webauthn_authentication(form_url: webauthn_authenticate_session_path)
  end

  def authenticate
    @user = current_user
    if verify_user
      mark_verified
    else
      flash.now[:alert] = t("profiles.request_denied")
      setup_webauthn_authentication(form_url: webauthn_authenticate_session_path)
      render :verify, status: :unauthorized
    end
  end

  def webauthn_authenticate
    @user = current_user
    if webauthn_credential_verified?
      mark_verified
    else
      flash.now[:alert] = @webauthn_error
      setup_webauthn_authentication(form_url: webauthn_authenticate_session_path)
      render :verify, status: :unauthorized
    end
  end

  private

  def mark_verified
    session_verified
    redirect_to session.delete(:redirect_uri) || root_path
  end

  def verify_user
    current_user.authenticated? verify_password_params[:password]
  end

  def verify_password_params
    params.permit(verify_password: :password).require(:verify_password)
  end

  def do_login(two_factor_label:, two_factor_method:, authentication_method:)
    sign_in(@user) do |status|
      if status.success?
        StatsD.increment "login.success"
        current_user.record_event!(Events::UserEvent::LOGIN_SUCCESS, request:,
          two_factor_method:, two_factor_label:, authentication_method:)
        set_login_flash
        redirect_to(url_after_create)
      else
        login_failure(status.failure_message)
      end
    end
  end

  def login_failure(message)
    StatsD.increment "login.failure"
    flash.now.notice = message
    webauthn_new_setup
    render "sessions/new", status: :unauthorized
  end

  def mfa_failure(message)
    login_failure(message)
  end

  def find_user
    password = params.permit(session: :password).require(:session).fetch(:password, nil)
    User.authenticate(who, password) if password.is_a?(String) && who
  end

  def find_mfa_user
    @user = User.find_by(id: session[:mfa_user]) if mfa_session_active? && session[:mfa_user]
    return if @user
    delete_mfa_session
    login_failure t("multifactor_auths.session_expired")
  end

  def who
    who_param = params.permit(session: :who).require(:session).fetch(:who, nil)
    who_param if who_param.is_a?(String)
  end

  def set_login_flash
    if current_user.mfa_recommended_not_yet_enabled?
      flash[:notice] = t("multifactor_auths.setup_recommended")
    elsif current_user.mfa_recommended_weak_level_enabled?
      flash[:notice] = t("multifactor_auths.strong_mfa_level_recommended")
    elsif !current_user.webauthn_enabled?
      flash[:notice_html] = t("multifactor_auths.setup_webauthn_html")
    end
  end

  def url_after_create
    if current_user.mfa_recommended_not_yet_enabled?
      new_multifactor_auth_path
    elsif current_user.mfa_recommended_weak_level_enabled?
      edit_settings_path
    else
      dashboard_path
    end
  end

  def ensure_not_blocked
    user = User.find_by_blocked(who)
    return unless user&.blocked_email

    flash.now.alert = t(".account_blocked")
    webauthn_new_setup
    render template: "sessions/new", status: :unauthorized
  end

  def record_mfa_login_duration(mfa_type:)
    started_at = Time.zone.parse(session[:mfa_login_started_at]).utc
    duration = Time.now.utc - started_at

    StatsD.distribution("login.mfa.#{mfa_type}.duration", duration)
  end

  def webauthn_new_setup
    @webauthn_options = WebAuthn::Credential.options_for_get(
      user_verification: "discouraged"
    )

    @webauthn_verification_url = webauthn_full_create_session_path

    session[:webauthn_authentication] = {
      "challenge" => @webauthn_options.challenge
    }
  end

  def delete_session_verification
    session[:verified_user] = session[:verification] = nil
  end

  def otp_verification_url
    otp_create_session_path
  end

  def webauthn_verification_url
    webauthn_create_session_path
  end

  def incorrect_otp
    delete_mfa_session
    super
  end
end
