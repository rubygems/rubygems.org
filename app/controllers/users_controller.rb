class UsersController < Clearance::UsersController
  include CaptchaVerifiable
  include PrivacyPassSupportable

  before_action :present_privacy_pass_challenge, unless: :valid_privacy_pass_redemption?, only: :new

  def new
    @user = user_from_params
  end

  def create
    @user = user_from_params
    render template: "users/new" and return unless @user.valid?
    if !valid_privacy_pass_redemption? && HcaptchaVerifier.should_verify_sign_up?(request.remote_ip)
      setup_captcha_verification
      render "users/captcha"
    elsif @user.save
      handle_user_after_save
    else
      render template: "users/new"
    end
  end

  def captcha_create
    @user = user_from_params
    verified = verified_captcha?
    if verified && @user.save
      handle_user_after_save
      delete_captcha_user_from_session
    else
      flash[:notice] = t("captcha.invalid") unless verified
      render template: "users/new"
    end
  end

  private

  def handle_user_after_save
    Mailer.email_confirmation(@user).deliver_later
    flash[:notice] = t("users.create.email_sent")
    delete_privacy_pass_token_redemption
    redirect_back_or url_after_create
  end

  def setup_captcha_verification
    create_catpcha_user(user_params: user_params)
  end

  def present_privacy_pass_challenge
    @user = user_from_params
    setup_privacy_pass_challenge
    status = privacy_pass_enabled? ? :unauthorized : :ok
    render "users/new", status: status
  end

  def user_params
    @user_params = params.permit(user: Array(User::PERMITTED_ATTRS)).fetch(:user, {})
    @user_params = user_params_from_captcha_user if @user_params.empty? && captcha_user_params_present?
    @user_params
  end
end
