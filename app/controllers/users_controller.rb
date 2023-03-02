class UsersController < Clearance::UsersController
  include PrivacyPassSupportable

  def new
    @user = user_from_params

    if redeem_privacy_pass_token
      super
    else
      setup_privacy_pass_challenge
      render "users/new", status: :unauthorized
    end
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
    session.delete(:captcha_user)

    captcha_success = HcaptchaVerifier.call(captcha_response, request.remote_ip)
    if captcha_success && @user.save
      handle_user_after_save
    else
      flash[:notice] = t("captcha.invalid") unless captcha_success
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

  def captcha_response
    params.permit("h-captcha-response")["h-captcha-response"]
  end

  def user_params
    @user_params = params.permit(user: Array(User::PERMITTED_ATTRS)).fetch(:user, {})
    @user_params = session[:captcha_user].symbolize_keys if @user_params.empty? && session[:captcha_user].is_a?(Hash)
    @user_params
  end
end
