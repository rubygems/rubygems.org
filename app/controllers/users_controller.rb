class UsersController < Clearance::UsersController
  include CaptchaVerifiable
  include PrivacyPassSupportable

  before_action :present_privacy_pass_challenge, unless: :redeemed_privacy_pass_token?, only: :new

  def new
    @user = user_from_params
  end

  def create
    @user = user_from_params
    render template: "users/new" and return unless @user.valid?
    if !session[:redeemed_privacy_pass] && HcaptchaVerifier.should_verify_sign_up?(request.remote_ip)
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
      session.delete(:captcha_user)
    else
      flash[:notice] = t("captcha.invalid") unless verified
      render template: "users/new"
    end
  end

  private

  def handle_user_after_save
    Mailer.email_confirmation(@user).deliver_later
    flash[:notice] = t(".email_sent")
    session.delete(:redeemed_privacy_pass)
    redirect_back_or url_after_create
  end

  def setup_captcha_verification
    session[:captcha_user] = user_params.to_h
  end

  def present_privacy_pass_challenge
    @user = user_from_params
    setup_privacy_pass_challenge
    render "users/new", status: :unauthorized
  end

  def user_params
    @user_params = params.permit(user: Array(User::PERMITTED_ATTRS)).fetch(:user, {})
    @user_params = session[:captcha_user].symbolize_keys if @user_params.empty? && session[:captcha_user].is_a?(Hash)
    @user_params
  end
end
